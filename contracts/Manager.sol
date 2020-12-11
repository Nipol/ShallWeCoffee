/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.6.0;

import "./abstract/Initializer.sol";
import "./Interface/IERC20.sol";
import "./Interface/IERC2612.sol";
import "./Interface/IManagerInit.sol";
import "./Interface/IUniswapV2Router02.sol";
import "./Interface/IUniswapV2Factory.sol";
import "./Library/Authority.sol";
import "./Library/SafeMath.sol";

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
