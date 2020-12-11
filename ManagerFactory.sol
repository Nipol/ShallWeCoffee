// Sources flattened with hardhat v2.0.4 https://hardhat.org

// File contracts/Interface/IERC173.sol

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.6.0;

/// @title ERC-173 Contract Ownership Standard
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-173.md
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @notice Get the address of the owner
    /// @return The address of the owner.
    function owner() external view returns (address);

    /// @notice Set the address of the new owner of the contract
    /// @param newOwner The address of the new owner of the contract
    function transferOwnership(address newOwner) external;
}


// File contracts/Library/Authority.sol

pragma solidity ^0.6.0;

contract Authority is IERC173 {
    address private _owner;

    modifier onlyAuthority() {
        require(_owner == msg.sender, "Authority/Not-Authorized");
        _;
    }

    function initialize(address newOwner) internal {
        _owner = newOwner;
        emit OwnershipTransferred(address(0), newOwner);
    }

    function owner() external view override returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner)
        external
        override
        onlyAuthority
    {
        _owner = newOwner;
        emit OwnershipTransferred(msg.sender, newOwner);
    }
}


// File contracts/Library/Create2Maker.sol

pragma solidity ^0.6.0;

contract Create2Maker {
    constructor(address template, bytes memory initializationCalldata)
        public
        payable
    {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = template.delegatecall(initializationCalldata);
        if (!success) {
            // pass along failure message from delegatecall and revert.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        // place eip-1167 runtime code in memory.
        bytes memory runtimeCode =
            abi.encodePacked(
                bytes10(0x363d3d373d3d3d363d73),
                template,
                bytes15(0x5af43d82803e903d91602b57fd5bf3)
            );

        // return eip-1167 code to write it to spawned contract runtime.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            return(add(0x20, runtimeCode), 45) // eip-1167 runtime code, length
        }
    }
}


// File contracts/Library/SafeMath.sol

pragma solidity ^0.6.0;

library SafeMath {
    uint256 internal constant WAD = 1e18;
    uint256 internal constant RAY = 1e27;
    uint256 internal constant RAD = 1e45;

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "Math/Add-Overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "Math/Sub-Overflow");
    }

    function sub(
        uint256 x,
        uint256 y,
        string memory message
    ) internal pure returns (uint256 z) {
        require((z = x - y) <= x, message);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || ((z = x * y) / y) == x, "Math/Mul-Overflow");
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y > 0, "Math/Div-Overflow");
        z = x / y;
    }

    function mod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y != 0, "Math/Mod-Overflow");
        z = x % y;
    }

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    function toWAD(uint256 wad, uint256 decimal)
        internal
        pure
        returns (uint256 z)
    {
        require(decimal < 18, "Math/Too-high-decimal");
        z = mul(wad, 10**(18 - decimal));
    }
}


// File contracts/Interface/IWETH.sol

pragma solidity ^0.6.0;

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256) external;
}


// File contracts/Interface/IUniswapV2Router01.sol

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}


// File contracts/Interface/IUniswapV2Router02.sol

pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}


// File contracts/Interface/IUniswapV2Factory.sol

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}


// File contracts/Interface/IERC20.sol

pragma solidity ^0.6.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function balanceOf(address target) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
}


// File contracts/Interface/ITokenFactory.sol

pragma solidity ^0.6.0;

interface ITokenFactory {
    struct TemplateInfo {
        address template;
        uint256 price;
    }

    event SetTemplate(
        bytes32 indexed key,
        address indexed template,
        uint256 indexed price
    );

    event RemovedTemplate(bytes32 indexed key);

    event GeneratedToken(address owner, address token);

    function newTemplate(address template, uint256 price)
        external
        returns (bytes32 key);

    function updateTemplate(
        bytes32 key,
        address template,
        uint256 price
    ) external;

    function deleteTemplate(bytes32 key) external;

    function newToken(
        bytes32 key,
        string memory version,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) external returns (address result);

    function newTokenWithMint(
        bytes32 key,
        string memory version,
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 amount
    ) external returns (address result);

    function calculateNewTokenAddress(
        bytes32 key,
        string memory version,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) external view returns (address result);
}


// File contracts/Interface/IManagerInit.sol

pragma solidity ^0.6.0;

interface IManagerInit {
    function initialize(
        address ownerAddress,
        address tokenAddress,
        uint256 minimum,
        uint256 burning
    ) external;
}


// File contracts/ManagerFactory.sol

pragma solidity ^0.6.0;










contract ManagerFactory is Authority {
    using SafeMath for uint256;
    address private constant UniswapV2Router =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant UniswapV2Factory =
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    address public WETH;
    address public tokenFactory;
    bytes32 public tokenTemplateKey;
    address public managerTemplate;
    // EOA to Manager
    mapping(address => address) public ownerToManager;

    event DeployedManager(address indexed owner, address indexed manager);

    constructor(
        address weth,
        address tokenFac,
        bytes32 tokenTemplate,
        address template
    ) public {
        Authority.initialize(msg.sender);
        WETH = weth;
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
        // 토큰 생성, 만들어진 토큰과 토큰 계약 권한은 이 계약에 있음
        IERC20(WETH).approve(tokenFactory, uint256(-1));
        token = ITokenFactory(tokenFactory).newTokenWithMint(
            tokenTemplateKey,
            "1",
            tokenName,
            tokenSymbol,
            18,
            mintingAmount
        );

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
            manager := create2(
                // call `CREATE2` w/ 4 arguments.
                0, // forward any supplied endowment.
                encoded_data, // pass in initialization code.
                encoded_size, // pass in init code's length.
                salt // pass in the salt value.
            )

            // pass along failure message from failed contract deployment and revert.
            if iszero(manager) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

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
}
