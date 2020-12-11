/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.6.0;

import "./Library/Authority.sol";
import "./Library/Create2Maker.sol";
import "./Library/SafeMath.sol";
import "./Interface/IWETH.sol";
import "./Interface/IUniswapV2Router02.sol";
import "./Interface/IUniswapV2Factory.sol";
import "./Interface/IERC20.sol";
import "./Interface/IERC173.sol";
import "./Interface/ITokenFactory.sol";
import "./Interface/IManagerInit.sol";

contract ManagerFactory is Authority {
    using SafeMath for uint256;

    address public UniswapV2Router;
    address public UniswapV2Factory;
    address public WETH;
    address public tokenFactory;
    bytes32 public tokenTemplateKey;
    address public managerTemplate;
    // EOA to Manager
    mapping(address => address) public ownerToManager;

    event DeployedManager(address indexed owner, address indexed manager);

    constructor(
        address uniRouter,
        address uniFactory,
        address tokenFac,
        bytes32 tokenTemplate,
        address template
    ) public {
        Authority.initialize(msg.sender);
        UniswapV2Router = uniRouter;
        UniswapV2Factory = uniFactory;
        WETH = IUniswapV2Router02(UniswapV2Router).WETH();
        tokenFactory = tokenFac;
        tokenTemplateKey = tokenTemplate;
        managerTemplate = template;
    }

    // @TODO: tokenTemplateKey 넣고 필요 금액을 가져와야 함.
    function newManager(
        string calldata tokenName,
        string calldata tokenSymbol,
        uint256 mintingAmount,
        uint256 requireAmount,
        uint256 burningAmount
    ) external payable returns (address token, address manager) {
        IWETH(WETH).deposit{value: msg.value}();
        IERC20(WETH).approve(tokenFactory, uint256(-1));
        // 토큰 생성, 만들어진 토큰과 토큰 계약 권한은 이 계약에 있음
        token = ITokenFactory(tokenFactory).newTokenWithMint(
            tokenTemplateKey,
            "1",
            tokenName,
            tokenSymbol,
            18,
            mintingAmount
        );

        manager = _newManager(token, requireAmount, burningAmount);

        uint256 wethbalance = IERC20(WETH).balanceOf(address(this));
        IERC20(WETH).approve(UniswapV2Router, uint256(-1));
        // router에 토큰 approve
        IERC20(token).approve(UniswapV2Router, mintingAmount);
        // 이더와 토큰 Uniswap pair 생성 유동성 추가 + LP 토큰 받음
        IUniswapV2Router02(UniswapV2Router).addLiquidity(
            WETH,
            token,
            wethbalance,
            mintingAmount,
            wethbalance,
            mintingAmount,
            manager,
            block.timestamp
        );

        ownerToManager[msg.sender] = manager;
        emit DeployedManager(msg.sender, manager);
    }

    function calculateNewManagerAddress(
        string calldata tokenName,
        string calldata tokenSymbol,
        uint256 requireAmount,
        uint256 burningAmount
    ) external view returns (address result) {
        address tokenAddress =
            ITokenFactory(tokenFactory).calculateNewTokenAddress(
                tokenTemplateKey,
                "1",
                tokenName,
                tokenSymbol,
                18
            );

        bytes memory initializationCalldata =
            abi.encodeWithSelector(
                IManagerInit(managerTemplate).initialize.selector,
                msg.sender,
                tokenAddress,
                requireAmount,
                burningAmount
            );

        bytes memory initCode =
            abi.encodePacked(
                type(Create2Maker).creationCode,
                abi.encode(address(managerTemplate), initializationCalldata)
            );

        (, result) = _getSaltAndTarget(initCode);
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

    function _newManager(
        address token,
        uint256 requireAmount,
        uint256 burningAmount
    ) internal returns (address result) {
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
                0, // forward any supplied endowment.
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
    }
}
