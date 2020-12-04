/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.6.0;

import "./Library/Authority.sol";
import "./Library/Create2Maker.sol";
import "./Library/SafeMath.sol";
import "./Interface/IUniswapV2Router02.sol";
import "./Interface/IUniswapV2Factory.sol";
import "./Interface/IERC20.sol";
import "./Interface/IERC173.sol";
import "./Interface/ITokenFactory.sol";
import "./Interface/IManagerInit.sol";

contract ManagerFactory is Authority {
    using SafeMath for uint256;

    address tokenFactory = 0xCc83Dd82FB74B5056De897B68244D0895a9a07e4;
    bytes32 tokenTemplateKey =
        0x000000000000000000000000644fE2731D8235216aA1DBfF4b4e844A9937173C;
    address UniswapV2Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address UniswapV2Factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address managerTemplate;
    // EOA to Manager
    mapping(address => address) public ownerToManager;

    event DeployedManager(address indexed manager);

    constructor(address template) public {
        Authority.initialize(msg.sender);
        managerTemplate = template;
    }

    function newManager(
        string calldata tokenName,
        string calldata tokenSymbol,
        uint256 mintingAmount,
        uint256 requireAmount,
        uint256 burningAmount
    ) external payable returns (address result) {
        // 토큰 생성
        // 만들어진 토큰과 토큰 계약 권한은 이 계약에 있음
        // @TODO: tokenTemplateKey 넣고 필요 금액을 가져와야 함.
        address token =
            ITokenFactory(tokenFactory).newTokenWithMint{value: 0 ether}(
                tokenTemplateKey,
                "1",
                tokenName,
                tokenSymbol,
                18,
                mintingAmount
            );

        // router에 토큰 approve
        IERC20(token).approve(UniswapV2Router, uint256(-1));
        // 이더와 토큰 Uniswap pair 생성 유동성 추가 + LP 토큰 받음
        (, , uint256 lpAmount) =
            IUniswapV2Router02(UniswapV2Router).addLiquidityETH{
                value: msg.value.sub(0 ether)
            }(token, 0, mintingAmount, msg.value, address(this), uint256(-1));
        // 매니저 생성 + 오너 EOA + 각종 설정(min use token, burning token)

        bytes memory initializationCalldata =
            abi.encodeWithSelector(
                IManagerInit(managerTemplate).initialize.selector,
                msg.sender,
                token,
                requireAmount,
                burningAmount
            );

        bytes memory create2Code =
            abi.encodePacked(
                type(Create2Maker).creationCode,
                abi.encode(address(managerTemplate), initializationCalldata)
            );

        (bytes32 salt, ) = _getSaltAndTarget(create2Code);

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let encoded_data := add(0x20, create2Code) // load initialization code.
            let encoded_size := mload(create2Code) // load the init code's length.
            result := create2(
                // call `CREATE2` w/ 4 arguments.
                callvalue(), // forward any supplied endowment.
                encoded_data, // pass in initialization code.
                encoded_size, // pass in init code's length.
                salt // pass in the salt value.
            )

            // pass along failure message from failed contract deployment and revert.
            if iszero(result) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        address weth =
            IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D)
                .WETH();

        // 매니저에 LP 토큰 전송
        address lptoken =
            IUniswapV2Factory(UniswapV2Factory).getPair(token, weth);
        IERC20(lptoken).transfer(result, lpAmount);

        emit DeployedManager(result);
    }

    function _getSaltAndTarget(bytes memory initCode)
        private
        view
        returns (bytes32 salt, address target)
    {
        // get the keccak256 hash of the init code for address derivation.
        bytes32 initCodeHash = keccak256(initCode);

        // set the initial nonce to be provided when constructing the salt.
        uint256 nonce = 0;

        // declare variable for code size of derived address.
        bool exist;

        while (true) {
            // derive `CREATE2` salt using `msg.sender` and nonce.
            salt = keccak256(abi.encodePacked(msg.sender, nonce));

            target = address( // derive the target deployment address.
                uint160( // downcast to match the address type.
                    uint256( // cast to uint to truncate upper digits.
                        keccak256( // compute CREATE2 hash using 4 inputs.
                            abi.encodePacked( // pack all inputs to the hash together.
                                bytes1(0xff), // pass in the control character.
                                address(this), // pass in the address of this contract.
                                salt, // pass in the salt from above.
                                initCodeHash // pass in hash of contract creation code.
                            )
                        )
                    )
                )
            );

            // determine if a contract is already deployed to the target address.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                exist := gt(extcodesize(target), 0)
            }

            // exit the loop if no contract is deployed to the target address.
            if (!exist) {
                break;
            }

            // otherwise, increment the nonce and derive a new salt.
            nonce++;
        }
    }
}
