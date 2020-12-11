// Sources flattened with hardhat v2.0.4 https://hardhat.org

// File contracts/Library/Address.sol

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.6.0;

library Address {
    function isContract(address target) internal view returns (bool result) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            result := gt(extcodesize(target), 0)
        }
    }
}


// File contracts/abstract/Initializer.sol

pragma solidity ^0.6.0;

abstract contract AbstractInitializer {
    using Address for address;

    bool private _initialized;
    bool private _initializing;

    modifier initializer() {
        require(
            _initializing || !_initialized || !address(this).isContract(),
            "Initializer/Already Initialized"
        );

        bool isSurfaceCall = !_initializing;
        if (isSurfaceCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isSurfaceCall) {
            _initializing = false;
        }
    }
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


// File contracts/Interface/IERC2612.sol

pragma solidity ^0.6.0;

interface IERC2612 {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
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


// File contracts/Interface/IERC173.sol

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


// File contracts/Manager.sol

pragma solidity ^0.6.0;








//@TODO: 기간을 정할 수 있어야 함. 기간에 따른 로직
contract Manager is IManagerInit, Authority, AbstractInitializer {
    using SafeMath for uint256;
    address private UniswapV2Router =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private UniswapV2Factory =
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    // 토큰
    address public token;
    // 유니스왑 페어
    // @TODO: withdrawable
    address private pair;
    // 최소 사용 토큰 수량
    uint256 public requireAmount;
    // 사용되었을 때 소각될 토큰 수량
    uint256 public burnAmount;
    // ipfs 프로필 json hash
    bytes32 private profile;

    enum State {Inactive, Requested, Progressing}

    mapping(address => State) private status;

    event Reserved(address booker);
    event Allowed(address booker);
    event Deny(address booker);
    event Finalized(address booker);

    function initialize(
        address ownerAddress,
        address tokenAddress,
        uint256 minimum,
        uint256 burning
    ) external override initializer {
        Authority.initialize(ownerAddress);
        token = tokenAddress;
        requireAmount = minimum;
        burnAmount = burning;
    }

    // 사용자의 예약
    // Approve에 따른 서명을 같이 제출 하여야 함.
    function reservation(
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(
            status[msg.sender] == State.Inactive,
            "Manager/Already-Reserved"
        );
        // 사용자의 지정된 수량 approve
        IERC2612(token).permit(
            msg.sender,
            address(this),
            requireAmount,
            uint256(-1),
            v,
            r,
            s
        );
        // 지정된 수량 토큰 끌어오기
        require(
            IERC20(token).transferFrom(
                msg.sender,
                address(this),
                requireAmount
            ),
            "Manager/Something Wrong"
        );
        // 메시지 발송인 로깅
        status[msg.sender] = State.Requested;
        emit Reserved(msg.sender);
        // 발송되면 대기 하도록 하여야 함.
    }

    // 예약 상태 가져오기
    function getStatus(address booker) external view returns (State result) {
        result = status[booker];
    }

    // 예약 발송인 주소 넣어서 확인
    function confirm(address booker) external onlyAuthority {
        require(status[booker] == State.Requested, "Manager/Didnt-Reserved");
        status[booker] = State.Progressing;
        IERC20(token).transfer(address(0x0), requireAmount.sub(burnAmount));
        emit Allowed(booker);
    }

    // 예약 발송인 주소 넣어서 취소
    function cancel(address booker) external onlyAuthority {
        require(status[booker] == State.Requested, "Manager/Didnt-Reserved");
        IERC20(token).transferFrom(address(this), booker, requireAmount);
        delete status[booker];
        emit Deny(booker);
    }

    // 약속이 끝난 경우, 페이백 여부를 결정하여 확인 할 것.
    function finalize(address booker, bool payback) external onlyAuthority {
        require(status[booker] == State.Progressing, "Manager/Not-Confirmed");
        delete status[booker];
        if (payback) {
            IERC20(token).transfer(booker, burnAmount);
        } else {
            IERC20(token).transfer(address(0x0), burnAmount);
        }
        emit Finalized(booker);
    }

    // 프로필을 업데이트 할 때 사용함.
    function updateProfile(bytes32 ipfshash) external onlyAuthority {
        profile = ipfshash;
    }

    function getProfile() external view returns (bytes32) {
        return profile;
    }

    function withdrawETH(
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external onlyAuthority {
        address weth =
            IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D)
                .WETH();
        address lptoken =
            IUniswapV2Factory(UniswapV2Factory).getPair(token, weth);
        uint256 lpBalance = IERC20(lptoken).balanceOf(address(this));

        IUniswapV2Router02(UniswapV2Router).removeLiquidityETHWithPermit(
            token,
            lpBalance, // LP Balance
            0, // min balance
            0, // min balance
            msg.sender, // receive address
            uint256(-1), // deadline
            true, // fully approve
            v, // signature
            r, // signature
            s // signature
        );
    }
}
