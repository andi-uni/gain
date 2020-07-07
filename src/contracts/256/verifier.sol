// This file is LGPL3 Licensed
pragma solidity ^0.6.1;

/**
 * @title Elliptic curve operations on twist points for alt_bn128
 * @author Mustafa Al-Bassam (mus@musalbas.com)
 * @dev Homepage: https://github.com/musalbas/solidity-BN256G2
 */

library BN256G2 {
    uint256 internal constant FIELD_MODULUS = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47;
    uint256 internal constant TWISTBX = 0x2b149d40ceb8aaae81be18991be06ac3b5b4c5e559dbefa33267e6dc24a138e5;
    uint256 internal constant TWISTBY = 0x9713b03af0fed4cd2cafadeed8fdf4a74fa084e52d1852e4a2bd0685c315d2;
    uint internal constant PTXX = 0;
    uint internal constant PTXY = 1;
    uint internal constant PTYX = 2;
    uint internal constant PTYY = 3;
    uint internal constant PTZX = 4;
    uint internal constant PTZY = 5;

    /**
     * @notice Add two twist points
     * @param pt1xx Coefficient 1 of x on point 1
     * @param pt1xy Coefficient 2 of x on point 1
     * @param pt1yx Coefficient 1 of y on point 1
     * @param pt1yy Coefficient 2 of y on point 1
     * @param pt2xx Coefficient 1 of x on point 2
     * @param pt2xy Coefficient 2 of x on point 2
     * @param pt2yx Coefficient 1 of y on point 2
     * @param pt2yy Coefficient 2 of y on point 2
     * @return (pt3xx, pt3xy, pt3yx, pt3yy)
     */
    function ECTwistAdd(
        uint256 pt1xx, uint256 pt1xy,
        uint256 pt1yx, uint256 pt1yy,
        uint256 pt2xx, uint256 pt2xy,
        uint256 pt2yx, uint256 pt2yy
    ) public view returns (
        uint256, uint256,
        uint256, uint256
    ) {
        if (
            pt1xx == 0 && pt1xy == 0 &&
            pt1yx == 0 && pt1yy == 0
        ) {
            if (!(
                pt2xx == 0 && pt2xy == 0 &&
                pt2yx == 0 && pt2yy == 0
            )) {
                assert(_isOnCurve(
                    pt2xx, pt2xy,
                    pt2yx, pt2yy
                ));
            }
            return (
                pt2xx, pt2xy,
                pt2yx, pt2yy
            );
        } else if (
            pt2xx == 0 && pt2xy == 0 &&
            pt2yx == 0 && pt2yy == 0
        ) {
            assert(_isOnCurve(
                pt1xx, pt1xy,
                pt1yx, pt1yy
            ));
            return (
                pt1xx, pt1xy,
                pt1yx, pt1yy
            );
        }

        assert(_isOnCurve(
            pt1xx, pt1xy,
            pt1yx, pt1yy
        ));
        assert(_isOnCurve(
            pt2xx, pt2xy,
            pt2yx, pt2yy
        ));

        uint256[6] memory pt3 = _ECTwistAddJacobian(
            pt1xx, pt1xy,
            pt1yx, pt1yy,
            1,     0,
            pt2xx, pt2xy,
            pt2yx, pt2yy,
            1,     0
        );

        return _fromJacobian(
            pt3[PTXX], pt3[PTXY],
            pt3[PTYX], pt3[PTYY],
            pt3[PTZX], pt3[PTZY]
        );
    }

    /**
     * @notice Multiply a twist point by a scalar
     * @param s     Scalar to multiply by
     * @param pt1xx Coefficient 1 of x
     * @param pt1xy Coefficient 2 of x
     * @param pt1yx Coefficient 1 of y
     * @param pt1yy Coefficient 2 of y
     * @return (pt2xx, pt2xy, pt2yx, pt2yy)
     */
    function ECTwistMul(
        uint256 s,
        uint256 pt1xx, uint256 pt1xy,
        uint256 pt1yx, uint256 pt1yy
    ) public view returns (
        uint256, uint256,
        uint256, uint256
    ) {
        uint256 pt1zx = 1;
        if (
            pt1xx == 0 && pt1xy == 0 &&
            pt1yx == 0 && pt1yy == 0
        ) {
            pt1xx = 1;
            pt1yx = 1;
            pt1zx = 0;
        } else {
            assert(_isOnCurve(
                pt1xx, pt1xy,
                pt1yx, pt1yy
            ));
        }

        uint256[6] memory pt2 = _ECTwistMulJacobian(
            s,
            pt1xx, pt1xy,
            pt1yx, pt1yy,
            pt1zx, 0
        );

        return _fromJacobian(
            pt2[PTXX], pt2[PTXY],
            pt2[PTYX], pt2[PTYY],
            pt2[PTZX], pt2[PTZY]
        );
    }

    /**
     * @notice Get the field modulus
     * @return The field modulus
     */
    function GetFieldModulus() public pure returns (uint256) {
        return FIELD_MODULUS;
    }

    function submod(uint256 a, uint256 b, uint256 n) internal pure returns (uint256) {
        return addmod(a, n - b, n);
    }

    function _FQ2Mul(
        uint256 xx, uint256 xy,
        uint256 yx, uint256 yy
    ) internal pure returns (uint256, uint256) {
        return (
            submod(mulmod(xx, yx, FIELD_MODULUS), mulmod(xy, yy, FIELD_MODULUS), FIELD_MODULUS),
            addmod(mulmod(xx, yy, FIELD_MODULUS), mulmod(xy, yx, FIELD_MODULUS), FIELD_MODULUS)
        );
    }

    function _FQ2Muc(
        uint256 xx, uint256 xy,
        uint256 c
    ) internal pure returns (uint256, uint256) {
        return (
            mulmod(xx, c, FIELD_MODULUS),
            mulmod(xy, c, FIELD_MODULUS)
        );
    }

    function _FQ2Add(
        uint256 xx, uint256 xy,
        uint256 yx, uint256 yy
    ) internal pure returns (uint256, uint256) {
        return (
            addmod(xx, yx, FIELD_MODULUS),
            addmod(xy, yy, FIELD_MODULUS)
        );
    }

    function _FQ2Sub(
        uint256 xx, uint256 xy,
        uint256 yx, uint256 yy
    ) internal pure returns (uint256 rx, uint256 ry) {
        return (
            submod(xx, yx, FIELD_MODULUS),
            submod(xy, yy, FIELD_MODULUS)
        );
    }

    function _FQ2Div(
        uint256 xx, uint256 xy,
        uint256 yx, uint256 yy
    ) internal view returns (uint256, uint256) {
        (yx, yy) = _FQ2Inv(yx, yy);
        return _FQ2Mul(xx, xy, yx, yy);
    }

    function _FQ2Inv(uint256 x, uint256 y) internal view returns (uint256, uint256) {
        uint256 inv = _modInv(addmod(mulmod(y, y, FIELD_MODULUS), mulmod(x, x, FIELD_MODULUS), FIELD_MODULUS), FIELD_MODULUS);
        return (
            mulmod(x, inv, FIELD_MODULUS),
            FIELD_MODULUS - mulmod(y, inv, FIELD_MODULUS)
        );
    }

    function _isOnCurve(
        uint256 xx, uint256 xy,
        uint256 yx, uint256 yy
    ) internal pure returns (bool) {
        uint256 yyx;
        uint256 yyy;
        uint256 xxxx;
        uint256 xxxy;
        (yyx, yyy) = _FQ2Mul(yx, yy, yx, yy);
        (xxxx, xxxy) = _FQ2Mul(xx, xy, xx, xy);
        (xxxx, xxxy) = _FQ2Mul(xxxx, xxxy, xx, xy);
        (yyx, yyy) = _FQ2Sub(yyx, yyy, xxxx, xxxy);
        (yyx, yyy) = _FQ2Sub(yyx, yyy, TWISTBX, TWISTBY);
        return yyx == 0 && yyy == 0;
    }

    function _modInv(uint256 a, uint256 n) internal view returns (uint256 result) {
        bool success;
        assembly {
            let freemem := mload(0x40)
            mstore(freemem, 0x20)
            mstore(add(freemem,0x20), 0x20)
            mstore(add(freemem,0x40), 0x20)
            mstore(add(freemem,0x60), a)
            mstore(add(freemem,0x80), sub(n, 2))
            mstore(add(freemem,0xA0), n)
            success := staticcall(sub(gas(), 2000), 5, freemem, 0xC0, freemem, 0x20)
            result := mload(freemem)
        }
        require(success);
    }

    function _fromJacobian(
        uint256 pt1xx, uint256 pt1xy,
        uint256 pt1yx, uint256 pt1yy,
        uint256 pt1zx, uint256 pt1zy
    ) internal view returns (
        uint256 pt2xx, uint256 pt2xy,
        uint256 pt2yx, uint256 pt2yy
    ) {
        uint256 invzx;
        uint256 invzy;
        (invzx, invzy) = _FQ2Inv(pt1zx, pt1zy);
        (pt2xx, pt2xy) = _FQ2Mul(pt1xx, pt1xy, invzx, invzy);
        (pt2yx, pt2yy) = _FQ2Mul(pt1yx, pt1yy, invzx, invzy);
    }

    function _ECTwistAddJacobian(
        uint256 pt1xx, uint256 pt1xy,
        uint256 pt1yx, uint256 pt1yy,
        uint256 pt1zx, uint256 pt1zy,
        uint256 pt2xx, uint256 pt2xy,
        uint256 pt2yx, uint256 pt2yy,
        uint256 pt2zx, uint256 pt2zy) internal pure returns (uint256[6] memory pt3) {
            if (pt1zx == 0 && pt1zy == 0) {
                (
                    pt3[PTXX], pt3[PTXY],
                    pt3[PTYX], pt3[PTYY],
                    pt3[PTZX], pt3[PTZY]
                ) = (
                    pt2xx, pt2xy,
                    pt2yx, pt2yy,
                    pt2zx, pt2zy
                );
                return pt3;
            } else if (pt2zx == 0 && pt2zy == 0) {
                (
                    pt3[PTXX], pt3[PTXY],
                    pt3[PTYX], pt3[PTYY],
                    pt3[PTZX], pt3[PTZY]
                ) = (
                    pt1xx, pt1xy,
                    pt1yx, pt1yy,
                    pt1zx, pt1zy
                );
                return pt3;
            }

            (pt2yx,     pt2yy)     = _FQ2Mul(pt2yx, pt2yy, pt1zx, pt1zy); // U1 = y2 * z1
            (pt3[PTYX], pt3[PTYY]) = _FQ2Mul(pt1yx, pt1yy, pt2zx, pt2zy); // U2 = y1 * z2
            (pt2xx,     pt2xy)     = _FQ2Mul(pt2xx, pt2xy, pt1zx, pt1zy); // V1 = x2 * z1
            (pt3[PTZX], pt3[PTZY]) = _FQ2Mul(pt1xx, pt1xy, pt2zx, pt2zy); // V2 = x1 * z2

            if (pt2xx == pt3[PTZX] && pt2xy == pt3[PTZY]) {
                if (pt2yx == pt3[PTYX] && pt2yy == pt3[PTYY]) {
                    (
                        pt3[PTXX], pt3[PTXY],
                        pt3[PTYX], pt3[PTYY],
                        pt3[PTZX], pt3[PTZY]
                    ) = _ECTwistDoubleJacobian(pt1xx, pt1xy, pt1yx, pt1yy, pt1zx, pt1zy);
                    return pt3;
                }
                (
                    pt3[PTXX], pt3[PTXY],
                    pt3[PTYX], pt3[PTYY],
                    pt3[PTZX], pt3[PTZY]
                ) = (
                    1, 0,
                    1, 0,
                    0, 0
                );
                return pt3;
            }

            (pt2zx,     pt2zy)     = _FQ2Mul(pt1zx, pt1zy, pt2zx,     pt2zy);     // W = z1 * z2
            (pt1xx,     pt1xy)     = _FQ2Sub(pt2yx, pt2yy, pt3[PTYX], pt3[PTYY]); // U = U1 - U2
            (pt1yx,     pt1yy)     = _FQ2Sub(pt2xx, pt2xy, pt3[PTZX], pt3[PTZY]); // V = V1 - V2
            (pt1zx,     pt1zy)     = _FQ2Mul(pt1yx, pt1yy, pt1yx,     pt1yy);     // V_squared = V * V
            (pt2yx,     pt2yy)     = _FQ2Mul(pt1zx, pt1zy, pt3[PTZX], pt3[PTZY]); // V_squared_times_V2 = V_squared * V2
            (pt1zx,     pt1zy)     = _FQ2Mul(pt1zx, pt1zy, pt1yx,     pt1yy);     // V_cubed = V * V_squared
            (pt3[PTZX], pt3[PTZY]) = _FQ2Mul(pt1zx, pt1zy, pt2zx,     pt2zy);     // newz = V_cubed * W
            (pt2xx,     pt2xy)     = _FQ2Mul(pt1xx, pt1xy, pt1xx,     pt1xy);     // U * U
            (pt2xx,     pt2xy)     = _FQ2Mul(pt2xx, pt2xy, pt2zx,     pt2zy);     // U * U * W
            (pt2xx,     pt2xy)     = _FQ2Sub(pt2xx, pt2xy, pt1zx,     pt1zy);     // U * U * W - V_cubed
            (pt2zx,     pt2zy)     = _FQ2Muc(pt2yx, pt2yy, 2);                    // 2 * V_squared_times_V2
            (pt2xx,     pt2xy)     = _FQ2Sub(pt2xx, pt2xy, pt2zx,     pt2zy);     // A = U * U * W - V_cubed - 2 * V_squared_times_V2
            (pt3[PTXX], pt3[PTXY]) = _FQ2Mul(pt1yx, pt1yy, pt2xx,     pt2xy);     // newx = V * A
            (pt1yx,     pt1yy)     = _FQ2Sub(pt2yx, pt2yy, pt2xx,     pt2xy);     // V_squared_times_V2 - A
            (pt1yx,     pt1yy)     = _FQ2Mul(pt1xx, pt1xy, pt1yx,     pt1yy);     // U * (V_squared_times_V2 - A)
            (pt1xx,     pt1xy)     = _FQ2Mul(pt1zx, pt1zy, pt3[PTYX], pt3[PTYY]); // V_cubed * U2
            (pt3[PTYX], pt3[PTYY]) = _FQ2Sub(pt1yx, pt1yy, pt1xx,     pt1xy);     // newy = U * (V_squared_times_V2 - A) - V_cubed * U2
    }

    function _ECTwistDoubleJacobian(
        uint256 pt1xx, uint256 pt1xy,
        uint256 pt1yx, uint256 pt1yy,
        uint256 pt1zx, uint256 pt1zy
    ) internal pure returns (
        uint256 pt2xx, uint256 pt2xy,
        uint256 pt2yx, uint256 pt2yy,
        uint256 pt2zx, uint256 pt2zy
    ) {
        (pt2xx, pt2xy) = _FQ2Muc(pt1xx, pt1xy, 3);            // 3 * x
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt1xx, pt1xy); // W = 3 * x * x
        (pt1zx, pt1zy) = _FQ2Mul(pt1yx, pt1yy, pt1zx, pt1zy); // S = y * z
        (pt2yx, pt2yy) = _FQ2Mul(pt1xx, pt1xy, pt1yx, pt1yy); // x * y
        (pt2yx, pt2yy) = _FQ2Mul(pt2yx, pt2yy, pt1zx, pt1zy); // B = x * y * S
        (pt1xx, pt1xy) = _FQ2Mul(pt2xx, pt2xy, pt2xx, pt2xy); // W * W
        (pt2zx, pt2zy) = _FQ2Muc(pt2yx, pt2yy, 8);            // 8 * B
        (pt1xx, pt1xy) = _FQ2Sub(pt1xx, pt1xy, pt2zx, pt2zy); // H = W * W - 8 * B
        (pt2zx, pt2zy) = _FQ2Mul(pt1zx, pt1zy, pt1zx, pt1zy); // S_squared = S * S
        (pt2yx, pt2yy) = _FQ2Muc(pt2yx, pt2yy, 4);            // 4 * B
        (pt2yx, pt2yy) = _FQ2Sub(pt2yx, pt2yy, pt1xx, pt1xy); // 4 * B - H
        (pt2yx, pt2yy) = _FQ2Mul(pt2yx, pt2yy, pt2xx, pt2xy); // W * (4 * B - H)
        (pt2xx, pt2xy) = _FQ2Muc(pt1yx, pt1yy, 8);            // 8 * y
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt1yx, pt1yy); // 8 * y * y
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt2zx, pt2zy); // 8 * y * y * S_squared
        (pt2yx, pt2yy) = _FQ2Sub(pt2yx, pt2yy, pt2xx, pt2xy); // newy = W * (4 * B - H) - 8 * y * y * S_squared
        (pt2xx, pt2xy) = _FQ2Muc(pt1xx, pt1xy, 2);            // 2 * H
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt1zx, pt1zy); // newx = 2 * H * S
        (pt2zx, pt2zy) = _FQ2Mul(pt1zx, pt1zy, pt2zx, pt2zy); // S * S_squared
        (pt2zx, pt2zy) = _FQ2Muc(pt2zx, pt2zy, 8);            // newz = 8 * S * S_squared
    }

    function _ECTwistMulJacobian(
        uint256 d,
        uint256 pt1xx, uint256 pt1xy,
        uint256 pt1yx, uint256 pt1yy,
        uint256 pt1zx, uint256 pt1zy
    ) internal pure returns (uint256[6] memory pt2) {
        while (d != 0) {
            if ((d & 1) != 0) {
                pt2 = _ECTwistAddJacobian(
                    pt2[PTXX], pt2[PTXY],
                    pt2[PTYX], pt2[PTYY],
                    pt2[PTZX], pt2[PTZY],
                    pt1xx, pt1xy,
                    pt1yx, pt1yy,
                    pt1zx, pt1zy);
            }
            (
                pt1xx, pt1xy,
                pt1yx, pt1yy,
                pt1zx, pt1zy
            ) = _ECTwistDoubleJacobian(
                pt1xx, pt1xy,
                pt1yx, pt1yy,
                pt1zx, pt1zy
            );

            d = d / 2;
        }
    }
}
// This file is MIT Licensed.
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
pragma solidity ^0.6.1;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() pure internal returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() pure internal returns (G2Point memory) {
        return G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
    }
    /// @return the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) pure internal returns (G1Point memory) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        assembly {
            success := call(sub(gas(), 2000), 6, 0, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
    }
    /// @return r the sum of two points of G2
    function addition(G2Point memory p1, G2Point memory p2) internal returns (G2Point memory r) {
        (r.X[1], r.X[0], r.Y[1], r.Y[0]) = BN256G2.ECTwistAdd(p1.X[1],p1.X[0],p1.Y[1],p1.Y[0],p2.X[1],p2.X[0],p2.Y[1],p2.Y[0]);
    }
    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        assembly {
            success := call(sub(gas(), 2000), 7, 0, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success);
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal returns (bool) {
        require(p1.length == p2.length);
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint[1] memory out;
        bool success;
        assembly {
            success := call(sub(gas(), 2000), 8, 0, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}

contract Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point a;
        Pairing.G2Point b;
        Pairing.G2Point gamma;
        Pairing.G2Point delta;
        Pairing.G1Point[] gamma_abc;
    }
    struct Proof {
        Pairing.G1Point a;
        Pairing.G2Point b;
        Pairing.G1Point c;
    }
    function verifyingKey() pure internal returns (VerifyingKey memory vk) {
        vk.a = Pairing.G1Point(uint256(0x1936c240636390dc823e3a728e94b208eb53c6756d81da57ec3425e05d43ac10), uint256(0x2d70ff78e8216bf29d58923a686d9738278b8ce2fd822e197c85b09286d15566));
        vk.b = Pairing.G2Point([uint256(0x2b4daf047abe2e7f0b311118c1b963b63695dc0d769cea78849604434de055bf), uint256(0x29c13ecb6f33dbc4b3b8a02e2e255511ce4c26a8a2f299efcc94caf2de4fce00)], [uint256(0x1da9020008df7f549751f8a251af3b2dc4a2ad3e0870de54acaedd9fc1b47e17), uint256(0x25ea0d7e2b29de431b86a943db30dbf4d98f68df9ca8a9628d14d1591e817d90)]);
        vk.gamma = Pairing.G2Point([uint256(0x011016e22ae045444f50fb80f246ec486c7e02af09132cd38c4fcf484983e4f2), uint256(0x00e83c788c2878d1d5eba3ed49b0d81e4c0487dedc3e4d1c2baab5833785b62f)], [uint256(0x05eb89e741ed5b5d611cebf92d1ed02cd6f3311089f0d400df7d9ced5a48fd41), uint256(0x132a90a3b0d369ccd66e2a5ba04a935e44d8ad5dca93a76bba592a578130a911)]);
        vk.delta = Pairing.G2Point([uint256(0x065f6a3323a2abffd621fc263f348eb914904b68d5897729ae34a6b9d33f0852), uint256(0x0c3b60f59d3bd50328a04c0ff6d979199685d0526f89f6ac29d6174ce24707a2)], [uint256(0x26e7ebce2b44efef6b6315938e33f0a8ecc82dbad635c9efa681ed85bbb59982), uint256(0x12e0f3721230a0f38f6c9913048d5230fd2615ef3ff7f6ee4b20dfe0bdea1a86)]);
        vk.gamma_abc = new Pairing.G1Point[](515);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x1c3aaffa42b64f8f9ec054d48a0ab69c45b4577b7d1af203fb4755ceabac9f01), uint256(0x20ea99136d7ebab6ab6e827c4079f598e32b2b23661d6a9ded8c98cff8b43142));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x23a4d730497df506773df2f0dfb4094a1816edecc033a179c16f363c6e713904), uint256(0x123e5000c9bef7bcd8ee9a1ac1bc83b57b8313039fca42f31218dcceb7e390d4));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x067f99bc99df346116de8f276f20c887fdfac42f3ec9689035ee643149b9c5e7), uint256(0x0e254579fca2996a8fef9be19e6f05c70f35402b17ea13d7f1b056526c5a52a0));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x0ad9cc52231f35ae74de7c9908953597ec3b54199c37e0f00b752776b581ef9b), uint256(0x2c6bed899699d794f30f8706c686dc47cfcc04aa5b7c7fbd2eecbc46b354250e));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x02cedf3557a2c877e25c676cef1cd94c1b789dd9d39e9ae053cbac222461f9b7), uint256(0x22941880412a921abe57418657ff7bb442c8847dd49e09c62d5e3330469fd3d9));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x28066ebf394464c0eae5617cce5593afc2b2aeb94dc2877ac1dc5e90779d5e34), uint256(0x19fb009486a15db2c94ad8548c2a91aabce629b3be75ef3d7c4e2197238c41db));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x205fe8a8ebf41aea759811ad16ff3aab6ba7d374481e69d3662520b7ea702190), uint256(0x1afc33d052f6f825881262c88a606820537730fa74665b630633a53b12058666));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x0730d0e311f52e17ea9c3e842ba831edd189433ad4f071368db809c367b95f23), uint256(0x03168a0f74213e7233f3d468f54a10593e851692e0f186fa855c12bc26304664));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x227edc5d801538ad9139aa48c78ea4ee91e656799f4796bb4cc24fb05f8e99e7), uint256(0x17ffecabee07c34cd495393d5bc02699064f7d69690b07bf8f9593abebb7c312));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x2e4f6451faa8dcee90f73aec82c4dee7c345cb076019e453e4943be5bb5d754d), uint256(0x1746397581c0ab2744d3a54926a90d994fb3d3a67bbb230175bbf39e9fc3bbee));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x0f247723c5a209c575dd114b6c03fda3800faef32e5eb3bb372efd698bc4bc70), uint256(0x082c4ab61d545cb730a50402c89708b727c8a22246d8cad69557284d714ab5b1));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x2dd84f1fc72cb40454f683368c00c2b13ba8e91299430f5899232d5a444d643e), uint256(0x1afe7c33a24e4143ecf56abccabb854590d9b857d11ad009d189f09871afc673));
        vk.gamma_abc[12] = Pairing.G1Point(uint256(0x26e38f2d108a7ba9f5d8b170b174464d9c642364b47a2c664ac14a1053546720), uint256(0x113790bbaa9e31ac30cdcb05ceaa400830238515d8ad85d33a3acbe98d5e1493));
        vk.gamma_abc[13] = Pairing.G1Point(uint256(0x2987e5ef712006b0a5bb35c86975737f5941ea1c53dcc37ef5007748083388db), uint256(0x2977e139268c6e127fac42665323e10962e6f366501fd69777228db565be4ebb));
        vk.gamma_abc[14] = Pairing.G1Point(uint256(0x02bd527ee35f87235e53fc016668baf2e8f9c191e4a0a41aff439b1dd7e484f5), uint256(0x128ca64b4eafed40df48ae2d9fa48579743cc940f6e90873de4f03797f0f1bc8));
        vk.gamma_abc[15] = Pairing.G1Point(uint256(0x0611f5376900032f4cb2729b4a3f3d9d45cc23a702f26f47000728e728c0bfea), uint256(0x1942674f93f3c382d26dbe950983035e3e7ee15871a434fe43d46c128797013f));
        vk.gamma_abc[16] = Pairing.G1Point(uint256(0x10379720b553ae560c5564d5ec1da62cd25e7f4d227914cd0dca6c7080f52cfa), uint256(0x0f29cbad01ceb18a3839caed60a3e2f8b80d1d150145d1317bb457485c9fd8ca));
        vk.gamma_abc[17] = Pairing.G1Point(uint256(0x2abda331cc61e63497c3ef57e5ce5bdf7df2991185f93a575dec8986b7e5a6a7), uint256(0x0e38397dcdbd28ea2d76fcfa44807ab96a728921cf0e4d2ff67339e66431f229));
        vk.gamma_abc[18] = Pairing.G1Point(uint256(0x060fc366995de7c622c044d7009469c1c23913279d539eff6d2ef2995c1c2346), uint256(0x0665a72b5a63546e6f4dfea1a8e5a7ecaa1e21a0b3c7cf647bfeb01affe7a3b7));
        vk.gamma_abc[19] = Pairing.G1Point(uint256(0x2de251419b66728546419094eb28c64f10b44c481d21e8b92fc2f5a71d100fe5), uint256(0x12d1582bbe5a01a3fe7c4af7412dae515e4868566922f1c1ac57924649eec0f8));
        vk.gamma_abc[20] = Pairing.G1Point(uint256(0x20e22987fee630f27742034e5f9eb99a3f57b7fde0c43dbd07aa5d58c38f95ce), uint256(0x0f0c15daec5fd9ee389d437dd3cdfeee5a15e4ab7073ca70558d92fe16ee64a7));
        vk.gamma_abc[21] = Pairing.G1Point(uint256(0x22e54070b7e31a1c513a3e6c2210e560ea85136b507b5022b0ba9b9144d39182), uint256(0x1ff027ec9f404a71e07c7ed63fb057881a6ca15758e4ff4b3bd9f5d6c11f53ec));
        vk.gamma_abc[22] = Pairing.G1Point(uint256(0x147cbc0d67c097863aeb4e942f3520c33faba95dfcf3bf38824409a7c2cc3686), uint256(0x194f6528f5a544ebb5cbc5117453348e1d1924e1362c59e310ad8097cb4d6221));
        vk.gamma_abc[23] = Pairing.G1Point(uint256(0x12a0fa2bc605fa09239703d5a5dee7700046358e18922adead71839399a69c6c), uint256(0x201f2d6c3fa2c149de4f09d606ccb75ddd77d65291fe749cce49a447c8b9b131));
        vk.gamma_abc[24] = Pairing.G1Point(uint256(0x1a48f7fe4997f791e2629147be8de7bb52a98b3aa75f7f84ee49d1eb237fcdb9), uint256(0x07696735de30e77d6b6f64f476c91c56e3b94fa50f7faa25fd178f1af99ee52b));
        vk.gamma_abc[25] = Pairing.G1Point(uint256(0x144d0b8f1096dde9070d5384b3ac252af106538c0b64ce6233309139e5a36ac6), uint256(0x1b9f9f159f4cb16a31d6c4df1a4afa14522d2135468e5a4d341e8a79304aa836));
        vk.gamma_abc[26] = Pairing.G1Point(uint256(0x07ea0a4155a379077a4e41e2e8959024b2dda7e07cbb307b3011df7d41b14fe4), uint256(0x10150ac40b91fdbdcabd05a617eb1e955ce1fd8bc9f41a540d664a700cca332c));
        vk.gamma_abc[27] = Pairing.G1Point(uint256(0x29a7ad81e93885a03b959ebf7ddd166bb7042e20ea098e2ac9a8ba167ca96193), uint256(0x05e5bcd2ef16ce5cc761af10cad3d33f06025841e420305cf24ce4c03a6c1757));
        vk.gamma_abc[28] = Pairing.G1Point(uint256(0x10d039d57ff75a4b0bb5c8a04dcb9a0dddabef6a23e1cca6f2c3481a5c38157f), uint256(0x03f5fff891c4fbe2b44c9ec9177e780fb78c4627435b44cae38e9a7138571000));
        vk.gamma_abc[29] = Pairing.G1Point(uint256(0x2a01a0ba4145c00ba64b5a9d7d9221be8174bbf448161dc8c4612a8a21a6d011), uint256(0x03b567d326526b0255ea97b72c9089ded2e64fef7af010093efd466ac77f306c));
        vk.gamma_abc[30] = Pairing.G1Point(uint256(0x06bb0a69da6650009ce48433ceefa16baf5e0f366b824be681e4ccbfab890c5d), uint256(0x18a6bc3d9a66e2fc251d09a830919a3690c36f62cb61a0c59a408def297e5656));
        vk.gamma_abc[31] = Pairing.G1Point(uint256(0x08caaa4f612a9d7ce0407abfb8c527b783bf3af132706013da763706b19a4e5c), uint256(0x1ae481ff04e77e6809d9f8f538046fcbe7526d4583b4998e2341f2e78dd5701e));
        vk.gamma_abc[32] = Pairing.G1Point(uint256(0x087e397e842af5d2a8117e20e554168e9c1813db51c0394dccf28e6cb3d78f43), uint256(0x192a02301ec6b12ac8907ebc97b2d0027e5df67a0a85efbb18921d7e14f1889a));
        vk.gamma_abc[33] = Pairing.G1Point(uint256(0x20b5d42183a2d3a0a2c627ae014d6d818cbaebe9d8cb02c0de67992f46e7d5d5), uint256(0x0688662fcfabd66a7607a728b9d6a273c3d2cfa8ecafb10a795668aeb953346c));
        vk.gamma_abc[34] = Pairing.G1Point(uint256(0x247716392207056afa52a08da3f44340a13941c5c3f1d406f290d5cf8d176bd4), uint256(0x05c8adf85c4dbe32417039034129f12200c07eb841cf849299cf2fd9db67ac33));
        vk.gamma_abc[35] = Pairing.G1Point(uint256(0x1ef38ddbc85ae399f56ecef243721fa0db8cf36201ae0417e2cb80db5ae3063f), uint256(0x2e903c1de94b6a79a321cfecc92d6ed797bb389fbe27c35a113582134d8960f8));
        vk.gamma_abc[36] = Pairing.G1Point(uint256(0x035014f45322bb3de389f7d04a2b95b4de2737fabb779b0154803195acf02050), uint256(0x221f1b1acb6cb8810359fda11060962b5f5b10214c47b1ef12a9ff526c60870b));
        vk.gamma_abc[37] = Pairing.G1Point(uint256(0x252a3587c5b8dbb3fef2303389f4c11d01b0318e1e2c9d31ee9c76919e23621d), uint256(0x00519b1ac7a7cc0794d7c8570eff1175314a662d63d8cb0922f4b5f7e8ba6a15));
        vk.gamma_abc[38] = Pairing.G1Point(uint256(0x1c2442c39a13b2b3456d867b9272f4cec0b787a1c7717a82388d15bccc7c30d5), uint256(0x24df19b777e709e065e11bae291a3fc5b94f24f14d137f0c67c67f563b9111df));
        vk.gamma_abc[39] = Pairing.G1Point(uint256(0x0c175f509242099d1a3200706e49d29391704be834abb704f10699a2605308fd), uint256(0x1904b4479c8679dfaf5aafcb320a679d125e4d772d72002b8dd73c011ec85016));
        vk.gamma_abc[40] = Pairing.G1Point(uint256(0x02888fe6103691aa20ec56aed2db4914b2d3470469257415fb1278c3b601270c), uint256(0x045348f594ebabcf70ea4f474d2599d3b50c0f40899e6a77a09d3cfe7e04b146));
        vk.gamma_abc[41] = Pairing.G1Point(uint256(0x23407a964aa9c6d201c3a9c92147b16c48ef53affd84fa31b744074c71b4d60a), uint256(0x03ab7d50169905bb37e531a6fb0e0b819c4bb05dbf294ff8906c317bcc5f1078));
        vk.gamma_abc[42] = Pairing.G1Point(uint256(0x2a89a1609c3f691dcbbf8abefbdb68b2c2035d50fa1e0abd4f48e1f6e5f948cf), uint256(0x2d9640516e3fe24655811eed194faf36af33bfabefa8782b79e6ca4e26b99ae2));
        vk.gamma_abc[43] = Pairing.G1Point(uint256(0x1db74d4ca96d7b86c9cb6c6d0eaa09d38f77c84e2436135a4db2d1edd63f1e21), uint256(0x1dbefbe7c97be4e0a16b7cebd92c21aa27006fb294bd9094ec496eaa56f03d4b));
        vk.gamma_abc[44] = Pairing.G1Point(uint256(0x0985e3481ce3df605bda2a95f83e39531d7b55e165f7ed8dc02541e3a38fce32), uint256(0x1fcdb7fac2b0dfaa123c76ccc95fb8fb3f3ffd17655b95f4a5fbcd4bb0282692));
        vk.gamma_abc[45] = Pairing.G1Point(uint256(0x2145d12ae9a7766047cea751a3dfc6d3bfe18fdca6a21542e8133c927b655839), uint256(0x2e33775da9e222937f0e8b72ab3352521cb3fd69a7490e90be04ac7688dfca09));
        vk.gamma_abc[46] = Pairing.G1Point(uint256(0x1c4963d4e8a6ba4d801ae7a443235a00df00982e567c7af326f2dcc888a109aa), uint256(0x21b40bf028a53860e8ff4a724910f90d0f905daf879b012f9860a2f8cef347a6));
        vk.gamma_abc[47] = Pairing.G1Point(uint256(0x1701e5806a2b22e5cfaa127fb029d8254f986664390a6473da5113e54bad688b), uint256(0x1b7e86958eec391f34708e78b58aec6e5f4a422c3bff8710a13b8864a06021fb));
        vk.gamma_abc[48] = Pairing.G1Point(uint256(0x21d0dfc3012e368ba884ae544f0118214012e7b312a6c5c13ad6f690bddf737d), uint256(0x003869cdc9f37c39250bcee9c258280585a792ab54e9455f05bea4d96bab0ab9));
        vk.gamma_abc[49] = Pairing.G1Point(uint256(0x1a844478d769c8665d9ba55652b1ea89c1d0fb2bfd752424927dd703d3962afe), uint256(0x26612a7c3041be123c8b1f8c7ddcb8f0e3db43a8a8b2855f9fb367d1ec3e3b08));
        vk.gamma_abc[50] = Pairing.G1Point(uint256(0x2003de228678b05f677ab519a96523893e062e1957622133dc5b2a0b1a7348d5), uint256(0x2788419f3f4b74fe1710b0bf6fa3f47cb99b79c363997dd9f5c968b6c06e868c));
        vk.gamma_abc[51] = Pairing.G1Point(uint256(0x255dffdf36ebfe85d3e52274805948aab3b20993e021b112b1a2c3aa9c6ead40), uint256(0x1c491e4ed6239fec754bdfaf4c251324b724619f8f29f9a23e6864e88a933574));
        vk.gamma_abc[52] = Pairing.G1Point(uint256(0x0d45667223b58093cede0aa6a4e1f4532ae68f26e5e754274d5ad01194814add), uint256(0x0ee969e727028e6c11bc4fc671018cdcbad7950e69fec6336f972fb07acbab34));
        vk.gamma_abc[53] = Pairing.G1Point(uint256(0x26cc9821d5d04c4ba8fce3f53012b65fdb4acacceb6915a5572f6938bf04dfda), uint256(0x2d54e8b445ea1d1065bf49d1bae2b2c47722d77c2e55a31b5f89a48b8e1728b7));
        vk.gamma_abc[54] = Pairing.G1Point(uint256(0x209f41db477a3ae713913d86157d0ea3e9648068b4408d0c294dd237b604e712), uint256(0x2c62f30766c5a60fce597e9ad256a3c23f9256fdc7d0bba8e133e8a201cc123e));
        vk.gamma_abc[55] = Pairing.G1Point(uint256(0x098f02f18f20da1acd5a1a7384880f9ab8d85d69fb525d761e1dc65d7af13613), uint256(0x218c873aedafcb3269a36b3439914becb107cf01413730e4cf0c4a483a702f2d));
        vk.gamma_abc[56] = Pairing.G1Point(uint256(0x1d10c0f5f9c95350c02f4f4026c7485a3ce3e955f876f6979b3c2af4fb96286d), uint256(0x24de55c8b3dc8262fb2ac3e3bfcf11108b15305edb0ebc0ec6af93b21dbfbe80));
        vk.gamma_abc[57] = Pairing.G1Point(uint256(0x16be6000711c57b855d91afb973d32565ba5916c0d30bc414367b6e6f3a27025), uint256(0x067bd7a06f254a1c8f9ef4d1bd350a75a5378afe6f6a12d0cb64103b8888e4a1));
        vk.gamma_abc[58] = Pairing.G1Point(uint256(0x1c047fff7237dfbd8cfc6ba28674d055aa97315f8e771677a1d1ad601ec37195), uint256(0x28e307a92e81d310eabb109b0ffe27754bd4aab7cbb09b1ddc926d9f1bdafd27));
        vk.gamma_abc[59] = Pairing.G1Point(uint256(0x156659841d35f2cfd8fabf8fe687b1994c646367c40399c75b890978d3d372b7), uint256(0x181648231394b1b624c205f5f55fa976e97e89d24783700efc8a4915454d4532));
        vk.gamma_abc[60] = Pairing.G1Point(uint256(0x03715dc600961212ac9d3a28f93e2fc7680d9c9cf3e856acfa4924cdfcfc0072), uint256(0x1cf76b253e9c2aa1d41bb55ab42bd0497c512750e3f81c490ff4ca868e243bb0));
        vk.gamma_abc[61] = Pairing.G1Point(uint256(0x1388ed222e2d267ea5bf5163721a48a101b3ecef7af1d3bc3120e57c497f7f9f), uint256(0x2966ffaf4350f99ad6ea97c1a1c1244613e254eb2b6a735142c9f038b4149b97));
        vk.gamma_abc[62] = Pairing.G1Point(uint256(0x03faa05dca2b6f35d8d96ecb5c1c15da6f741fc2c9bc1935dd1f894e7b29c47f), uint256(0x298cba6fed26c8fb16c2038906b436c497128b26973d3a71c801fa05d7dddf1b));
        vk.gamma_abc[63] = Pairing.G1Point(uint256(0x16a73d85d4509bde1af36b5dede86979155845d173a227c1465739e3f94ba346), uint256(0x06eff7bcdc604ab181e2457d97faca075f87a7d136b96383ede5857a8477d558));
        vk.gamma_abc[64] = Pairing.G1Point(uint256(0x19cec34c0da770ac3d01fb269a4d0f2254cde2f4fbe804340ae885aa8ce2a931), uint256(0x2dc0696e618df0b05654eed1e1e202ac2a9f3537dbb6e1033d131c20ef6bcb13));
        vk.gamma_abc[65] = Pairing.G1Point(uint256(0x20ad0ba117b88ca76267cbbe58a35bc81f495286cffdfe66c0e319480e195b94), uint256(0x14bfb18cccca7d0dc960c901e3feef23e968d7589e24abc550b6462b4d1fb61e));
        vk.gamma_abc[66] = Pairing.G1Point(uint256(0x2d48b083817946a3a3a12a23fe847d01f4b79d0089bbc72cfdce1fd83cd53765), uint256(0x2fad96360875035c37b12f8956dc528151a5f1fa53dc905d1ac57dae04f8d20a));
        vk.gamma_abc[67] = Pairing.G1Point(uint256(0x04f566c22450e299b77dbc27674728ed3d3bf4987110bc0bf7a1bc461d002b70), uint256(0x1037d772ee17f4a5cf891f50308243a0293a673d03266f058cfd55e1cadb3e90));
        vk.gamma_abc[68] = Pairing.G1Point(uint256(0x0b19de58f5e53866ef2600ff3d117a4ace4939d2beb325a3174ed3cd4a1ac98c), uint256(0x1ebb2c8e6915ce2c4dadb890d7f2f3b73d581d4eabbd3b688417846096e4a859));
        vk.gamma_abc[69] = Pairing.G1Point(uint256(0x1f3c50c950f3fc29581d3a0f878da0a1fc0a3d2cd793a76c842921e1c1784f52), uint256(0x2a6097170e8e8642a1ca83ed91adbcc6d6d87642bbd008823be8521edc07bec8));
        vk.gamma_abc[70] = Pairing.G1Point(uint256(0x2c472ee017afd42e0bee40fc3d94d7d6d1be753312ba31ffc1395bdff017e621), uint256(0x213eb625a9cb2a42bda2761077e40d5338e7b536a11fbc177395e6ec229cf8b1));
        vk.gamma_abc[71] = Pairing.G1Point(uint256(0x25a43b7df234f8f7cc4b7261691dd837693b61d524d175f4be9c0ba091abf18c), uint256(0x2e85cda2861783f3ed254a6adf6fbd6d6909f4a1e5f3911760adbb2d3129fed3));
        vk.gamma_abc[72] = Pairing.G1Point(uint256(0x1fade7a516920ba22ab5b9911165cd1375cc13b7c005836466184adeb870ede7), uint256(0x026c65667c099365fe332a521e58f919fc0267a1c127800fe1de198457412e98));
        vk.gamma_abc[73] = Pairing.G1Point(uint256(0x198e834fed1c0ebf98bc1af4f035a97a1a32a7a82ae697a32a51298998a83fd9), uint256(0x194480cc5d56abe5c82f76ef5a930f06011fe7af836c727d4a43ce905980c4c6));
        vk.gamma_abc[74] = Pairing.G1Point(uint256(0x2fca5c2644d34e3012a9cd1b46223ff4b3f2b8c1fca9ba11087b37decfed4e1a), uint256(0x1d303586eac5f775eb979dff046d59d093a1a2478e359a5dc1772365f822269a));
        vk.gamma_abc[75] = Pairing.G1Point(uint256(0x0a3f31c9f793aace5e2c3a8fca38cfb1329492cd446f9c1c539a7ba7a424b705), uint256(0x0969ab807a1e8eb94af2dc97c89cf1cb41e188c33b78ac8e7371ce00f61c5466));
        vk.gamma_abc[76] = Pairing.G1Point(uint256(0x02b5ef04700e84c307a9530adc8cdd8849c7ea33c342179636adbb1ee447d55c), uint256(0x2cad1f12b0eda7e760bbd37e71c473570fd6a04186d723bd53c06c76413b741a));
        vk.gamma_abc[77] = Pairing.G1Point(uint256(0x2ce431386c9e032c312efd4a095ef24fca3445a07e7189e49a7fa56976e7e9d0), uint256(0x2837ffbb7d69ce4058b6721b74e12f6b9cc0ed7b090ae01969dc71d2d7185844));
        vk.gamma_abc[78] = Pairing.G1Point(uint256(0x14d715c2eb592cc737fbfadc57b546e12283e8c3bd8dfbbb586d88fa565b0ce4), uint256(0x2901518a5b130a41f95c45a1415e4f056ce4c520d31dc598955e545c60c7266c));
        vk.gamma_abc[79] = Pairing.G1Point(uint256(0x053cdbd0b629f2da53fc581c0fc69dfd1f877146d8a96c4aa63edcda83e9e04c), uint256(0x2262c69e6db98247a852ed5d7cbcd88454c6ab1fdb33004ade47d67ed3fe7222));
        vk.gamma_abc[80] = Pairing.G1Point(uint256(0x2cb6859a982825a82fcee62845215964dda65008c3b0d70ef8a4d04acbca9e3c), uint256(0x267e2e35de3ea241b7a552c18a1f81d50888e23867f36f9597e4208497868117));
        vk.gamma_abc[81] = Pairing.G1Point(uint256(0x0e99770c401a64dae5ab26844a1330d451d485a9abf6e9459462089059a33671), uint256(0x0e18e15b9adb1105f528c5ec19b4e71d75fd6611198509137d1805495aa47d09));
        vk.gamma_abc[82] = Pairing.G1Point(uint256(0x0ccb98b831b344b1a344390980f1a03dc882d6d39250a1801a47f8d3fcf6aa6c), uint256(0x0c3f76ecedcb362617cc6cc622bc4043b6df34d9ace95baeaa2e53fae101399a));
        vk.gamma_abc[83] = Pairing.G1Point(uint256(0x0a4d7d94a55d968c60664b67203531bcd56390efc6470dc7c2c99eb7672a8593), uint256(0x1a582e500b3d41dd71bbef5d277e1b3156fe097e6f94c7f3f4b3bfef6bcdb50f));
        vk.gamma_abc[84] = Pairing.G1Point(uint256(0x1df0ae0833f4fbfd911e7031692be627d88b0c4b76e6fc5145926037f74488d8), uint256(0x12b1dc4d06703c8bbbe9314cfbbb29dd3ff0f136ca28fe74e0139bbd37641595));
        vk.gamma_abc[85] = Pairing.G1Point(uint256(0x00934106a7a2444bc492d2cd1b89cf4634b20a64ad27661dd23de6db3e2a6b27), uint256(0x1b62da53370ee299d2c2bb4604f5f4456bd591940a98904f610e76c62c12caef));
        vk.gamma_abc[86] = Pairing.G1Point(uint256(0x29dfd83e972d4d9e81a2a62947a2b80dd53cdfbe015434e54cb36e7cdd77c076), uint256(0x29a4e4bb2bef4042666698bb582a63738a1419a4e26efe84ac98244a5f7e4fb9));
        vk.gamma_abc[87] = Pairing.G1Point(uint256(0x13d6675d5a412b7554d7ccd4b8b5b5f153395d4de9cd52be24474dda32d48132), uint256(0x24d9bc9f80900a491bf8aa3a060430250c2e720657671f6719575c4830c1314c));
        vk.gamma_abc[88] = Pairing.G1Point(uint256(0x177c620aa4098dd6ac44c569f8a81c28601615f5620240d455dd01e6f13bbdcd), uint256(0x2b20c49912c82154e115507533353ce39d9fd219bfd15517160249b80a0ba852));
        vk.gamma_abc[89] = Pairing.G1Point(uint256(0x1834cd458052840d30e56a65bd60dd4b385be5804b1b9412d896553efd8aa9b4), uint256(0x1f2449779c5d06c0870df3523c713f3001076221446a42f7e70e32a462573271));
        vk.gamma_abc[90] = Pairing.G1Point(uint256(0x1026d49a881c98ceb2163d31cc00ad78700e1b8754cc7395f7dfcb53722372cb), uint256(0x2910b3faa608a9a290cee55694a414112fa375a9744ddee772b4c4276a381216));
        vk.gamma_abc[91] = Pairing.G1Point(uint256(0x1bdf1eab7505233f25aaf329908dd0e5a635ca6fdb62832da54b688d43ff8f83), uint256(0x2181beb926be313d370286b60dcb7471228ca30766f54c04777bf1bba8253608));
        vk.gamma_abc[92] = Pairing.G1Point(uint256(0x0832e5c20e43eaf63ae0cd9d41a3b417849301ecaf7b3511753af440c0e13a46), uint256(0x0024b1f7c3d97bb03a6d04e3709fdbc2a7fc777f2f51b4044dbc9a84d98ca66e));
        vk.gamma_abc[93] = Pairing.G1Point(uint256(0x2c6ba7622f2ffd432ce1487a46b3230665be3feb7cddeffa2b6773ed574537f7), uint256(0x29ed420928f590540cfcf40be329ae04aba2046642c894a5e2c081b7e625a062));
        vk.gamma_abc[94] = Pairing.G1Point(uint256(0x1969360554b6d85de466f669ee5af6dcd12079eb15182d8292e4a44fddfca83e), uint256(0x1396768e31a14ac1e6b09dbec55f982d759ab6eb275ac907fcb9d5d22f6449d1));
        vk.gamma_abc[95] = Pairing.G1Point(uint256(0x267831be24d821870685dc302c13d707d7570d6be11c8e06bba4ac88e26d69c5), uint256(0x2776592d0a3a8b9c8afb1d6343e24243cfe763ef4c7657fff89fb2da89cc6b5d));
        vk.gamma_abc[96] = Pairing.G1Point(uint256(0x08914b14053066efcef0a41c1bb9a7d0b5f38c1efd3b5a3691c0f9bd47857aea), uint256(0x2456bade5bd0cbf00f9c0aa0fe5ca210500d9458bfe43ca5119360a2631325b6));
        vk.gamma_abc[97] = Pairing.G1Point(uint256(0x1c5d359a0c33ecfc2c196c5762af293f86b0cc661fcc598bf8ef294008989dab), uint256(0x0f06d29b2e52eb6c2fe82dedbd2bd57e53eff754342a5d61130c4459d516a20d));
        vk.gamma_abc[98] = Pairing.G1Point(uint256(0x03a46dd125f087818566b8231aeda93a3eec800db9d325ff2060cf1b7b2fefc0), uint256(0x1c0dbc73c1008ae7cd969169d4b0af48b213f61881bd2f8a204a00ffcbcfbdbc));
        vk.gamma_abc[99] = Pairing.G1Point(uint256(0x08c3bf505335b2ef783b623784eb9fefa3a38cc91c75d9a9fa86fdd6718d719b), uint256(0x07f94c3a68af55aee564e498253ceeb339bbe0dc2f5fbee6afa56cfcc4964c76));
        vk.gamma_abc[100] = Pairing.G1Point(uint256(0x10fd8317bd895272448dd97105d0450ed27aa03ea6ef624c3f888203a3ea64aa), uint256(0x25a8cfa6581b695c5087845bfa51dd3dadd973f30d4159ffdda979e1517e3fce));
        vk.gamma_abc[101] = Pairing.G1Point(uint256(0x17afc83ecf40e603dc0e72796bb57fc37af8064edda2458bf6653fae9044c780), uint256(0x283ef83a0bce037c2cfffb8638dcb9b51960932a38b8d00c69974de346c1c856));
        vk.gamma_abc[102] = Pairing.G1Point(uint256(0x2950b13d77e1f0277edbeaff2725bebe39cb17971c9e29dea9e2c595f5e56235), uint256(0x02fb0d3b7d60c5d29fbffe160026a0bd65a03c9a1f568775fd04fe439d12614d));
        vk.gamma_abc[103] = Pairing.G1Point(uint256(0x2d4741d79062b537261e0a2ee49bb32a2c7d084e22e51f6c37a5367a5f159477), uint256(0x1d558120c88d51d2c3a9ca429769cb2d544b0965aecd445f61b715cf9b4215dc));
        vk.gamma_abc[104] = Pairing.G1Point(uint256(0x09c98e8905ea12edbb360f0172403fac32313f748bf854780f5035f6376e8b35), uint256(0x23276486b42aac1da059cf2e9a638c392454f885e31f662cf476d8237c76f031));
        vk.gamma_abc[105] = Pairing.G1Point(uint256(0x29f96a697009183e175188f118ef74a514da6f63efb2f40a9683d7b065e64fce), uint256(0x1a220f31c8e139a7539a339e9128b1e6e5694a9ff70ad8bc94c6ff452046ca6b));
        vk.gamma_abc[106] = Pairing.G1Point(uint256(0x07c983f1f47592f1db09ce7f51eb30335feb6f8e80e9e2702ab9ab43e32e0995), uint256(0x0b6bb971462e6977e27f3aeb25d94bc10463c79fc04d98ff2a637ca31bb1d4c1));
        vk.gamma_abc[107] = Pairing.G1Point(uint256(0x2da99d56b51245e431f4d88c9f424bb02f0a3eee39ec5f2f87590c3d8a9be4b7), uint256(0x236162e776ad2e8392aafd5f44f895703b9742c49a224435c2b2cd584fdf7b30));
        vk.gamma_abc[108] = Pairing.G1Point(uint256(0x05be0ea7a7c277eecb2ac4d27b67754a849b81e4deeffd1ffb3bea5fc1bbb58f), uint256(0x02c4aec88a5ef76bab53e5a5d69d41f393bbb6899c5e314b15cd9e0d65fecdb1));
        vk.gamma_abc[109] = Pairing.G1Point(uint256(0x25ee907d07827a75721a2616911039fb8c0f5cf9a4ffac11d8631d75e104c780), uint256(0x28d6faac25b3fe8c4d2118638c376d1f24af2935a18d0169f10ad1bd369ffc8e));
        vk.gamma_abc[110] = Pairing.G1Point(uint256(0x2e66a7707ec9b98f18bb67f8ed8cf3345f372c99ab952a202cfd875d980fdabe), uint256(0x14d0071634e5725a79bf9c6ef6772e801e6ef0d140010c67026a8a28ccdb3654));
        vk.gamma_abc[111] = Pairing.G1Point(uint256(0x230e0ebefdd14ced7d879915eb5db352d135def846594c0282942c3e7e2e397d), uint256(0x17f28edc438aae6b5a2281da88b7643dce98e91ac1a77c5fed477692ba5bc133));
        vk.gamma_abc[112] = Pairing.G1Point(uint256(0x0b452fb928ebf2d125b76eec2e6d7da9b61e1903a7af695e5e9e0dd8a3c20884), uint256(0x15e4cf8f66d4e4b0b290536c19ac537de4e3a969cca31b649fc7928a235e100a));
        vk.gamma_abc[113] = Pairing.G1Point(uint256(0x1e72a215afb51b4cdcf43d585d94f565e072f9fc1291104e02b82313875582d6), uint256(0x19e11bee075d1e90a6f99dca5f47cd3bcf0033abde1fe2e00dba78fa1455ee73));
        vk.gamma_abc[114] = Pairing.G1Point(uint256(0x120842d8046e15b51a0505ee504574cb32890bbebf86cb6c7190f2260e125313), uint256(0x1cb2c56edd4875a1f920cd90580758ee56caa92e447accb6f9597909af368db4));
        vk.gamma_abc[115] = Pairing.G1Point(uint256(0x243fdef14c8a598c5d4df9d21d15935446eff58decec1c303a8472fff26afce6), uint256(0x130392c322afb93aa686eb37f13009c3846364877e5efa27a6e6b565d69707ab));
        vk.gamma_abc[116] = Pairing.G1Point(uint256(0x04dc7bc2e2fa68f9c74431b2b28fcaf363a6e22649a243326fc7c52db2cc6ba3), uint256(0x2e6479245c569a5a937ef0069bb14f78f49f0a89deefedd4c83d78b09f4b30e0));
        vk.gamma_abc[117] = Pairing.G1Point(uint256(0x2edeb3a42d3cd853b9371137424ced4432e9bf876557009676efe52eb15a5739), uint256(0x2a4b4ac2ea544c18ba51aab50ba04c7e47398bb9eefbe55c03201ae0ad1bf77e));
        vk.gamma_abc[118] = Pairing.G1Point(uint256(0x00d8de1f3395ef970493bb0503ab5d6df16a84375d97d42b27b089f791fba228), uint256(0x050c83f032ac0db723ea057c21eb7eccd1fed5456c0767a8424c8833906b4036));
        vk.gamma_abc[119] = Pairing.G1Point(uint256(0x2e77c6e2c26588bd0d703f1c3292e6aa012a0f95e1cf596150e02dfdc13ccc6d), uint256(0x2a9b75cef6505b863b5ede773ee2b22bfefa4c4029e9074975634289976d305b));
        vk.gamma_abc[120] = Pairing.G1Point(uint256(0x2975cc1e62e34e4faed828c3512b2a5535393c28dcaf33374a212212acf23bed), uint256(0x25c5516881283844bd76c0dcd7c34a0588a6209d2cedf203a01d4b4c3eb4ea51));
        vk.gamma_abc[121] = Pairing.G1Point(uint256(0x1af6a2f13cbde926bb142a74e28359b1e3c360aa56eb22c39496ce5a69d1c8a0), uint256(0x216b822a85617ad6a6649d443e67372117f42a2d477e28aac7d70a94935c8f5e));
        vk.gamma_abc[122] = Pairing.G1Point(uint256(0x1fee4ddf132274937cd95936a207d2e02e53796a7a25d26727cc11589e47b290), uint256(0x15dc936ed52a558bffc83e642ea6c788803d57a8a4e5976e3da7b0637a4cec9a));
        vk.gamma_abc[123] = Pairing.G1Point(uint256(0x1c1b1e9e5e9df2a8e3774bbf25a13866b75dbd463d0469398393e427732ec1ec), uint256(0x1e926d9142d68a86d54ca58454c8a3218ad743b0da42003e26a06236e16d6166));
        vk.gamma_abc[124] = Pairing.G1Point(uint256(0x0a2902e1f2184b40ad1ae2330cd1fc6d91b7f7f28ba6fe068ae519f5de8506f7), uint256(0x01a916a6bf481419efc718466525c6b55eaa218c85a6648a24a31c12b6566829));
        vk.gamma_abc[125] = Pairing.G1Point(uint256(0x0ed7ac045aa39806b8bc86d54e90229af0ead8aa8121b133de5c6c68b8c0cb7a), uint256(0x2ce18ca0a15d35456a7766cc4aa4c97f32ebd1fa61d4656ee4733a6e3e1e7c7b));
        vk.gamma_abc[126] = Pairing.G1Point(uint256(0x06ded726d7620f8f74c1f274492589404ccabf535ede503457d272bb08f62710), uint256(0x03e6c29dc12e8b7fdd00b15934cbe3f2bc70abc0050ce5fa1190db8a7033f394));
        vk.gamma_abc[127] = Pairing.G1Point(uint256(0x04d9cc26bc3b2568d51a0e1c1f1fffef5e5a23cfcf1662974704df84e06af888), uint256(0x22333f716182d16487c0839a9e975f23e10d0b7d5cce7fa3c6f581ea80e22964));
        vk.gamma_abc[128] = Pairing.G1Point(uint256(0x27081a23d17f4f45cab63c750e93ff6719ce0e6e32b88ec598be810b26a55cb8), uint256(0x0f13ee8f1a73728043f5e1cc6404cddf54bda7593a99984483b7f1f96677bb2c));
        vk.gamma_abc[129] = Pairing.G1Point(uint256(0x1df5ac3db5c3e64301057e504614b0a31ac2831f6ac3bbf0e23a246cce6b0ae8), uint256(0x2c2fc91895170cfca8acd49036a1dfa35b7e0d96e6476496c9014e90507dfd6e));
        vk.gamma_abc[130] = Pairing.G1Point(uint256(0x248ddf1087763fbd3e2fca50a5d78802c6516a38635d8fc637ed3209859ced12), uint256(0x28d7338c7a8f79a649d7e46cbbdcc2b66ba9102e3e02330d2b776960afaffe95));
        vk.gamma_abc[131] = Pairing.G1Point(uint256(0x1f53a4d41ae05a2d575a3044bf3a6207c3c0e81f7fe9cbe446ce460fd2dc9277), uint256(0x16d061547461fa24f360163e860338de0558c7dfdb8d5b062af711ed155cfe9e));
        vk.gamma_abc[132] = Pairing.G1Point(uint256(0x2cddaabaa0b09438f1dcba82f972817d186fe3e7178710ee8435579b1305449e), uint256(0x154f145f4203749ca44694c851d4e1f0d911167c3087a16916761593c71d8207));
        vk.gamma_abc[133] = Pairing.G1Point(uint256(0x1d0012afc3470fbd37181a40a3e904e55a27018bad99f63de741efbe4bd48f89), uint256(0x2d09b111f03e63ac36364198dd670e8b329fdad25a7b4c86944905f5b97e11c5));
        vk.gamma_abc[134] = Pairing.G1Point(uint256(0x12e01f4bc399e2a20ab545c8630885eb820cbcb7b29fa8f0d36ee185d31a7540), uint256(0x1c1898eec4975eca8a226ae5a5486204c5c737204280140e016b9a83b44b6ec8));
        vk.gamma_abc[135] = Pairing.G1Point(uint256(0x2929177658de1036d1e217096efdeaed8f04151030278e7e9f4bbdc69c57d227), uint256(0x17c0b34952328d85badd9559416fba4f47549037e13ae696768f8694e65e1558));
        vk.gamma_abc[136] = Pairing.G1Point(uint256(0x2394a8c86e903dfcc277eefb319b298d252df7565d620bed20f5e7ebdf26b2ee), uint256(0x0dc55d1e7bbf21ba8cd515096b1ab0d86f6d256e0222f137af7075c4f090f99e));
        vk.gamma_abc[137] = Pairing.G1Point(uint256(0x1d9a4e682c5ec037ed6d82436edd4ec5d14cc769dc1cf339832d44d650a9419c), uint256(0x11e08911e8997958f8aae2c16e146d8cbe8af1f845cc57557579c57f070bbb3c));
        vk.gamma_abc[138] = Pairing.G1Point(uint256(0x2f3dee40538f74a9a3a45ac16a9a86394e475573064539b2db93008dd2304596), uint256(0x1e4709b6c820c028c85b8e6f49bcd33d7c5877c62326ee5606c28c3c3971e532));
        vk.gamma_abc[139] = Pairing.G1Point(uint256(0x2aac8efeb6a6e280dcd77f9a0f591d1bfc8db215ef530e881ecb4e969d6f917e), uint256(0x019aae2ad901986d0dc4c8d1ae92bf3fae6e8bb3e3e0d1d4850576c7a8ac79e4));
        vk.gamma_abc[140] = Pairing.G1Point(uint256(0x29e09bff63e5f9baf09cc97cb42596fadda22f43c037283549a5f7a2130f143b), uint256(0x26ae568e7962c617591ad79cea0e57800f672a9bb65141bc60a55be3906a9339));
        vk.gamma_abc[141] = Pairing.G1Point(uint256(0x0c8a315be236760e8202584a6ff8fc187db85e1b9991ec7d712f486ea4a8f3b8), uint256(0x056b4b506a2e7efeff4a801db0e9eee2fb01c2f76ffc2db0b41e0efb0f7d42ec));
        vk.gamma_abc[142] = Pairing.G1Point(uint256(0x1933ec55a24c08364b8a2ec5651677790f061ce69d24bd1ecdd32ef4422d43d5), uint256(0x0375340bd743a7ba0aafb314ada3f7c451a8b62607315a487ae66c88cfdaf5f1));
        vk.gamma_abc[143] = Pairing.G1Point(uint256(0x1b08ac29738e81283c592c27fa5b9a44ea723c136d0b5a6895d9e1e89844c7c8), uint256(0x10055d1228c619eaa0713283efc7c9b4f5fae5fce4c1c5a1ebe11b77fe80c307));
        vk.gamma_abc[144] = Pairing.G1Point(uint256(0x1de405c83dd6d5e177ee0d85707730c672166e091841ee5d9ba59d104259f8af), uint256(0x17b033d4427dc41ad56ad0ea2efad77f85dd7e4fc68dcce76baafe7748311329));
        vk.gamma_abc[145] = Pairing.G1Point(uint256(0x0806cf006e3971a56ddbf8d2f1afdc0f5a619e4c46ae31f7c549e03b2b9d7e3d), uint256(0x232a362b71655c078146cc2a82217bbf0dfcb99c9e4ca604cbafe4ea575349db));
        vk.gamma_abc[146] = Pairing.G1Point(uint256(0x0a3678b0d3dc852b8a45bffa6e3a9503f4d34be31771b0b736b45b8f9b9c3d3e), uint256(0x1054e42e17fef2f55977e8866c7f121b3ce94424636ac84f5a8f865ab258f34a));
        vk.gamma_abc[147] = Pairing.G1Point(uint256(0x11ee625933e78fcc8caa3f2976fdd744bfcb6c91363a42c7032aa8c03e3799eb), uint256(0x089ebd8894508b0d2d9c478d681d86947b68bc81ca24cd5a6fdea8a4afebd385));
        vk.gamma_abc[148] = Pairing.G1Point(uint256(0x236ac31705b7dc06a07b3c53427c5ddfa35907b1451614257696799618f8fc9a), uint256(0x125c9ba59b4bc9710a4e0f7ac2dd132b7c2cb7d4035c643aff54fd77231468f9));
        vk.gamma_abc[149] = Pairing.G1Point(uint256(0x1f6d8184f3535cac77ae4e44f4d2eb6e31fcc48451c8554a28ba2b782c661b3b), uint256(0x1e7648db9ebf14d34fb2d2f7feb7b4bc478dd7a31d2404437235410afb02d0d2));
        vk.gamma_abc[150] = Pairing.G1Point(uint256(0x10913734a84b602ee228ff82e452e1e05f05699b77d362a9c7033c44acf4c6ea), uint256(0x20f4b73f384a337e893b1720e6752508f65bea642b18316ee27bb0a0bef6e2d7));
        vk.gamma_abc[151] = Pairing.G1Point(uint256(0x0cf7beb481594c0e52f53ba025b2a757441172829c8a32c42532d9ad37960268), uint256(0x20e71149e0b637659c829726bbcbabcae9d07b77e4819407ee40921edbe8b3b8));
        vk.gamma_abc[152] = Pairing.G1Point(uint256(0x272e81ea5c116f078b9d09a5c6503bf70d34280dd195756be187bbac71d94685), uint256(0x26e1a513f6a2ddb7a9c45c25e7282c2258902fc2ff0df695f65099e1356372c4));
        vk.gamma_abc[153] = Pairing.G1Point(uint256(0x1a7ad902d9b255cca80813a2e058a4ec7f03a3bc61cb603f258bef0cbd97e456), uint256(0x12b0713d47c88d38e4e6d6fe067945dc07dc6130d971258433d31b72e8f449f5));
        vk.gamma_abc[154] = Pairing.G1Point(uint256(0x00ab19ae25192e75c5ebd33ba979011c0c87904707e283890aceb1681908e1cb), uint256(0x0cc82e30a54a0371c8ec89b6c0f60778e4aeb4dafc9f5d76b656d626708a3142));
        vk.gamma_abc[155] = Pairing.G1Point(uint256(0x2d9a2b0785d7b6d553cd84a394b283ae7cdf7a73b7ccc33401cefb4c8736504c), uint256(0x0f409c76cd6a84de4d1e893806288019230c4fe8932bd615b7091ca5bfd391bd));
        vk.gamma_abc[156] = Pairing.G1Point(uint256(0x16fcca4c2a9a408afe7110836073999a6da22ec8fbc36e2f4299c0b19462ee3a), uint256(0x2f87adb4fe7a7b7c2fe325c6697da139916eb09ed6e120d8d7beaa5efb7f524e));
        vk.gamma_abc[157] = Pairing.G1Point(uint256(0x180b8b0f9846e705ea89746a1c9036b7ac165bc3974432ff8a812c28373c5a39), uint256(0x2a8481877b67c9cf9dae968bde29aafea7acf6b70b3517f858ac4f2e612f6f27));
        vk.gamma_abc[158] = Pairing.G1Point(uint256(0x22629625c04c59172edd07631946da5ff6c7f137fe4a559979b8e23cfe7f6083), uint256(0x0120966dad495b3934aabc866c7258007839d61cbe6ca34fd9decd89cdc8d6a4));
        vk.gamma_abc[159] = Pairing.G1Point(uint256(0x2dcc74b0c5549ef529ce6bfab14b267b8f7a7f9e2742d92261274b578e57b383), uint256(0x07f4bf22a38c157a12b4093b3bf0b64a8521687a490f1ecdc09837bd4e80340e));
        vk.gamma_abc[160] = Pairing.G1Point(uint256(0x2aad465c5cf0a50419d7381dd425e50bb2d142ea4bf06291dd34a221022ec77c), uint256(0x09305deb4d774af4f9ec4aa3e1435e89b297cda7856b3a34570cd4f71e7979cb));
        vk.gamma_abc[161] = Pairing.G1Point(uint256(0x18c9ee9466879997bd24c82e026ba106ad92e1302f5ecfbc6f16c34a1c183959), uint256(0x1a06b98d049f985626d03ac6a6cf4fe63e81a2596af9329f6cb80f1411e4a167));
        vk.gamma_abc[162] = Pairing.G1Point(uint256(0x04e7293518afe704e88e7bc59995b066e649e1d87f1583bc9dde029d1dcb92d9), uint256(0x0d95b29f9ad64448f47e00178e2a7acfafb688c39e42a469fc903bf044e3f2f5));
        vk.gamma_abc[163] = Pairing.G1Point(uint256(0x0bedcef8fb12dde94fb1ef7172a0266e52929b1eddc4b070be14aad184c6af55), uint256(0x18ec8d096a9f703dfca93f6d299ec9a68acedca80fd917f41c26931cf2e831d5));
        vk.gamma_abc[164] = Pairing.G1Point(uint256(0x28bcd2eae72d4821e14e31fd1e643ae3a86641c43ae39b05f09852dcb40c3139), uint256(0x15e45c984ab503ebecfe917d3669f3b31ac5849362d0f4df9d150c1194eadff5));
        vk.gamma_abc[165] = Pairing.G1Point(uint256(0x0f832c42c456764d7c79c933069ba5d605507b6d3184c23abacf840af4d69d1e), uint256(0x018052b5804e5536d7641a9b89dca7814308b927138726bdcb3878e6d4961d9f));
        vk.gamma_abc[166] = Pairing.G1Point(uint256(0x0095dd845d25959e223d664cf9ac50886a81566289b48816f9222ce80963f01f), uint256(0x23bd966b2827c1b209af722cfab77e10b68f55552fa50f6d70cd2b03c1134d02));
        vk.gamma_abc[167] = Pairing.G1Point(uint256(0x1da0c8d4db0cf81c3bc87478d5e74a61ff6a70d67b24141c1314776af620e335), uint256(0x19ffb1e791d9b54b456ed99467df33792d09e2f0c0512412c104515a7c15f9ac));
        vk.gamma_abc[168] = Pairing.G1Point(uint256(0x21c1f7d7da2de8e46294b9df437969f15cf15417420db56b0d42abed679bdcb1), uint256(0x0ee83cd52a9e771bfefee6eae6547540af7d40c3433da3209c859cfb648484a4));
        vk.gamma_abc[169] = Pairing.G1Point(uint256(0x0edbf5ac55d44f244c940ff11f9dd8bd7d5e4db37e00d8bd2d57f20859ffe4b1), uint256(0x0682d906479db2a7de5b783ed358d65478fddd5a9b8b8ca423868681d63ad152));
        vk.gamma_abc[170] = Pairing.G1Point(uint256(0x08b0db49c02f4779f8e7b217e1b75300cf93755138074e885c6eef4595606159), uint256(0x09373ef78a68658624c5d78cc51368b2f099b456413a4f96952331876491da3c));
        vk.gamma_abc[171] = Pairing.G1Point(uint256(0x2245eae57a16d8288552c0fe531dfa6cda5e1edbba0f73bcb76e87561b56144e), uint256(0x243357f3a3ea55c6cd739e05cb7f4f9c79cceca69501bffe3a1110afbb592789));
        vk.gamma_abc[172] = Pairing.G1Point(uint256(0x0e60eb75934fd60b4ff0367f93783c5ff1090b8d967d63d9295f192d648c175b), uint256(0x0432d486f108c674a425d719a022c378e6d739105ba64815ff06fb044dfdc758));
        vk.gamma_abc[173] = Pairing.G1Point(uint256(0x02946f051396460d5ab98cad01ec7e913d3e17797be6a6a08217cda764114343), uint256(0x26d7c89ea4f04ed7f43d1593b91c280fad216bb6ee0113918dfb1cfd3e8a6f78));
        vk.gamma_abc[174] = Pairing.G1Point(uint256(0x0bd58e1eea5d18e58897f058f32a9e6328771f5488c3a88387ac716d1e7f17b3), uint256(0x2435da3a88ca3249564de20e07893d7faca30ca9ab130a90b096d7df8cb6d6e9));
        vk.gamma_abc[175] = Pairing.G1Point(uint256(0x006076ce3bd69c9f93fa444ab7963d4ea25fa51fba36b1a0ab6e795972801ff1), uint256(0x293f8adf5c255b4abffb52bd6637254bff920f03406760dbed097138db75a6ed));
        vk.gamma_abc[176] = Pairing.G1Point(uint256(0x0edb92f0ce3243101b30c612ac0f91560496e542fb81a305681363967e98112d), uint256(0x2cab162cf48543bb0f5708502d254e026233250355d9711b04157172189772b7));
        vk.gamma_abc[177] = Pairing.G1Point(uint256(0x14611dabb29cf7d9e22fc05a4a0767e0d20636716178804689feadd4e3ace12a), uint256(0x16e4b71aa079f02ef182931e49afb8c3c448ce0ac0f0b7ceec78a15f907df3f8));
        vk.gamma_abc[178] = Pairing.G1Point(uint256(0x12ed26b60d0f388bd0a6631d836f1dcea88eff0f2e303db1a0ca71ce86ee08d0), uint256(0x11e2bc0ad4812f81c80fb8dc45f14ba4090fe423bd5d034f2063437044531ba9));
        vk.gamma_abc[179] = Pairing.G1Point(uint256(0x25952b7b94131ea19a0f5df8c37d5ddf474fb8020ae92b6ef4d2462290c241f9), uint256(0x047243010ff9b688d3cec370e265dd89289c58445dc9e20dd89347cd27f572ec));
        vk.gamma_abc[180] = Pairing.G1Point(uint256(0x1aa41a3ed6e25c10c94ba4ad9868014ac5170c2cd6ae605f12bba97269e0acc1), uint256(0x0df910d54902b8d8012c7de517eebf5f7d741cbc1e2b9de8f466be9fca9a63ed));
        vk.gamma_abc[181] = Pairing.G1Point(uint256(0x01d0b08ccc35e669938c6d8246ca759eb829306e2b55b33d2e72c3a7faa7dcdc), uint256(0x2408654bfea365c138de4004e20c363aafc41e76ba1f2d83f3f21104e21b23da));
        vk.gamma_abc[182] = Pairing.G1Point(uint256(0x05baf08758e8a5460798597f21f5f662da0548459f8e063991a5d34535b55da0), uint256(0x1b04368793e0a0627e450caad81126ecb91f88a423b5c2dfb331d6850dc8ade6));
        vk.gamma_abc[183] = Pairing.G1Point(uint256(0x232e90cf66173fc7df415b97c1c78e5a93e77c0957247321c1f5ca9ad1811791), uint256(0x1f193ff03e440558d066e24ffee14e37546ace6814a1f287808098b4d49d1a0a));
        vk.gamma_abc[184] = Pairing.G1Point(uint256(0x273d47c7e56058fac15ed62dd338ba94ea0cd10ad61ba986628e7ee9b42ecc9c), uint256(0x23365842660e33ffd0c04c354454568148fade3ed44c0c50c490401a284fe25f));
        vk.gamma_abc[185] = Pairing.G1Point(uint256(0x19d3cf045cb1da638444944500ace0b52e9b8632e19673a63319dbf76ed40d92), uint256(0x0c6371f5edb495b7f5413aae343a92dad3c03d7435614ededad36235026638ba));
        vk.gamma_abc[186] = Pairing.G1Point(uint256(0x174dda5ea7a04adac4f398a49a58ec3ded71a807bdb1b83e397ff994dc6673c1), uint256(0x21d962955c505b3431aa981f92868a2fc9e68acc46a3e88fc36e378579eadb48));
        vk.gamma_abc[187] = Pairing.G1Point(uint256(0x28643812f8c6321b505c1e424de147084b18bf0a703872d28829f1803ed386d0), uint256(0x24e4e5a98857789baedc0cae2cddadc22c1723323dd665d8dd1bcb4d3c8e6f74));
        vk.gamma_abc[188] = Pairing.G1Point(uint256(0x07c6d055562cc3f25fb02bccbd5a36b3d7f7725ad63f446736c8b0e3bd65bc6c), uint256(0x055a28dd9d7565e27549813f04c8aa42383812191d85b356165c72bf4839cc88));
        vk.gamma_abc[189] = Pairing.G1Point(uint256(0x13af8db32f7a4ec700a99c616ba822f13f9e9b47eacf5f30ef8206afb2691095), uint256(0x0a19730ae4d78251503686d515e19253a7a394a0ad81ffd93ac1ee0142d02483));
        vk.gamma_abc[190] = Pairing.G1Point(uint256(0x210eac6fff433b733a575fb97cd57cc4fe672507e06d8a07c3500c36aab4cc9f), uint256(0x1980d1d35d8244c6c9419c3826de7c9b4a1e65d94bd553a0bfdd6b441910241f));
        vk.gamma_abc[191] = Pairing.G1Point(uint256(0x1480939aa77728589b89afccd5b1bb47c4192eb4dfa472908e30d5f537238a77), uint256(0x23f23ce17af0415a4c5b5f7e85e51d6e89c41e8f1ff044de6724c56708e95a07));
        vk.gamma_abc[192] = Pairing.G1Point(uint256(0x2e62936404cf544661d156688b3673bbb34e2f3ce7af4732dbc960f1a2cc5eac), uint256(0x1ba4c7752a0a0f97aec006f0870ed5328c16ee9571d152aa00b35fb6796037de));
        vk.gamma_abc[193] = Pairing.G1Point(uint256(0x0761413a04ec1675cc508b70f11234ae9ee4a887d7b9c8b73b599216b09b9ddc), uint256(0x17621dc4f3c3ae50ea9b373b7fc9ee16bce59b144a125a295e7578f9e1199025));
        vk.gamma_abc[194] = Pairing.G1Point(uint256(0x19cc26a166e55a468bd00d28a9a2339491d6c89b199d3f42d68a1a7f2df2b856), uint256(0x10184a87b71dedaf842b373d987e012607ecb94920eaac340687cbbb133b11ec));
        vk.gamma_abc[195] = Pairing.G1Point(uint256(0x2271bad0433a296b2518d87c4b83442059b290046aa55a3e48a75da60a7c5d46), uint256(0x106f46a33c6932d28ee596b272c156f13b32b1599db2721d711c83f7083e1699));
        vk.gamma_abc[196] = Pairing.G1Point(uint256(0x0375c929d53a6966e8a9a4a584888b69e06c5c947d7c16a0fee90fd39d279734), uint256(0x2baabc39a2f55ee7ffd39c452273955249b05d6c0433ec57828336691ffbf5c4));
        vk.gamma_abc[197] = Pairing.G1Point(uint256(0x0eb2b84ff1e5a13fd5cad3eec05231a1a304859d4aaf68301abbfc44d6a4723a), uint256(0x29195e5af07d525c9c2bb7d58af69548e024c745d343893207a95ec3b9ef952f));
        vk.gamma_abc[198] = Pairing.G1Point(uint256(0x1f738023a5b22d343ecf807c48d5d3436871dd0e8d87afe2ed53b1f95b7943ba), uint256(0x167505015c35e13f1506ba62643446ee729b885daac5ec14fb8d18906cc6144e));
        vk.gamma_abc[199] = Pairing.G1Point(uint256(0x160c6dfbf682c1b16b11b18311e1b1aafcdd175736c662e16d941225a1e26fbb), uint256(0x1f05525f9836eff822830e471b8bc7c74a207939a6f10298df130a49b2f39d87));
        vk.gamma_abc[200] = Pairing.G1Point(uint256(0x0870f4ae13a4479ed78f74ca75cedcc93b44da5ddd36a3607b8dce68bbecaf3b), uint256(0x0703b912709ac972c08e8d776553b73b121abebc220d93aec1c7d14a4a2dab24));
        vk.gamma_abc[201] = Pairing.G1Point(uint256(0x1eec778bf43d7174e88bf30d868184435f394fc19846212480fcfa7f6f0e9caa), uint256(0x158afebc692b1f51ed5128a0ee8cdb52e4a85fe9ad36d650fcead52dbeb02a60));
        vk.gamma_abc[202] = Pairing.G1Point(uint256(0x09f7411774f73f68ea0548843017c0c5fa96e273d035d6de6ef19f974a901d3b), uint256(0x0a6de3a9eb9b8e2060f7311bbd451d983ed15092004b7d29b8ece899b1f5a81b));
        vk.gamma_abc[203] = Pairing.G1Point(uint256(0x177c034f0545945439b1b609a953c8f61245db34daf9d2324a59941343eb96e0), uint256(0x0f38c07e625b67499b75a5bf4e3dc1ebd74c29dd63e5a501295eacbd52f5c5fb));
        vk.gamma_abc[204] = Pairing.G1Point(uint256(0x27448488463d9dd8a1bcc0915a5a4ed8ca49ad0daa08a023cfd48a4f7b445b25), uint256(0x1e851c0c8b7befb4fd5e3e128f74e4b61338fdedf1d866e68b6e0fe852535b3d));
        vk.gamma_abc[205] = Pairing.G1Point(uint256(0x1db4b1c954d5b47014d80473b0d6878db686a1b0d2b8c34c6b9f6b4a11dc990e), uint256(0x131f20927e774e5ceb7de060e00e91a8dd1665b4576426c7d86090a073c470b7));
        vk.gamma_abc[206] = Pairing.G1Point(uint256(0x2f6b435e587439e29d05db69339e18cbad4585b25c77a0c5490ae579e2e2feb9), uint256(0x0f26fd98219f19148bed2bab580224e42fe124d9de2d9ed57b6d20b476121af7));
        vk.gamma_abc[207] = Pairing.G1Point(uint256(0x2764b7920cf1ebb8c21ff05c6257af202b120148f3d1e3988eedae46616393ef), uint256(0x086f82bfc04ae1e7ff0e699b485b37262403e6b3409f3cbe0832909e6540b7f0));
        vk.gamma_abc[208] = Pairing.G1Point(uint256(0x21db9a33777dfc193dc797c2e48f42dba96cd0a1b417b3ebbcc701a5f3b52b1d), uint256(0x13b3474514fcae604705a6d71406dfd9144eea83675aaa1f0d87b5c670ec5f87));
        vk.gamma_abc[209] = Pairing.G1Point(uint256(0x0ed1b0733ccaa5c66a6f76c6874d2f96dd9f9ebbf67fedff91a55a7d69ce2c43), uint256(0x10f7f73c4ffb14657067440ddf7bd656a8304bf95775fe79358086e1a9e3b536));
        vk.gamma_abc[210] = Pairing.G1Point(uint256(0x0de885a0b066cad0f81847a3da62b9f99ae18ec15844305a4a4f68cc887516ec), uint256(0x20bd62cb485a618ef7a3857b406a5667d44027ebc140bca453c70b943ec236a1));
        vk.gamma_abc[211] = Pairing.G1Point(uint256(0x1bffca675c9ccb99242e542716fb5ffccac03322a645c6c5bcb2312cdfeb7365), uint256(0x2ac0766b2b0d5a99064bc18f1e89a842a7d24bf43c920c7c45ad1b2d271308a0));
        vk.gamma_abc[212] = Pairing.G1Point(uint256(0x08c623c102bbceff56db240374788a40525e29e6eb58fdf787e96440b9decdcf), uint256(0x248e3c867243cdbabad695d56c53defd15d2999c32f95b295096c1d5e30a99b7));
        vk.gamma_abc[213] = Pairing.G1Point(uint256(0x120f521769d374fcdeea9de115974f5ff5a84aefb8bbf40eaba58712f7bff68b), uint256(0x0a9bb8017dfe15872540e9c938ed6c64118692457a6ddb8dd1cfa2b29fa8436d));
        vk.gamma_abc[214] = Pairing.G1Point(uint256(0x0bb53fb304eda363ddd519e090eb05269abc8b29301e3f8b9b71980ba4a37d94), uint256(0x2de38a01d47002794f4b9f1997548b603c1117622ec2182b58a0c1deb51156bf));
        vk.gamma_abc[215] = Pairing.G1Point(uint256(0x2b89c6f740a24e6a37099912a7fc9c1e9f841a838784385409237a110ce531a5), uint256(0x117cdef7605a6b9fbf9c09b345f364412e03d04b43729c106539c3756b47c0cf));
        vk.gamma_abc[216] = Pairing.G1Point(uint256(0x18d255369d14ef7307fb89e9dc8457383ed748ad15b780615005a854418e8db9), uint256(0x0fa6750a4098a18f2c42e4da4d71fbdca4dfe6efc844df5e7fce249ec78a6aed));
        vk.gamma_abc[217] = Pairing.G1Point(uint256(0x07b27dd0515ea7a1681f7e760e58b6733e6c5b5f36b151be3952524163d2e806), uint256(0x1a1e4d953ffe7e3b30cb9c71ab15a058769f2969fd689ae39d7ee8ea6ba67430));
        vk.gamma_abc[218] = Pairing.G1Point(uint256(0x2c508d33cca83f5c571665bba037e700159f6f64a269f1dcc61610c1fc98732e), uint256(0x2b7da77733c4620f7207f7d11a211f4c1bc04daa1736aff3d3be6591936c02d5));
        vk.gamma_abc[219] = Pairing.G1Point(uint256(0x02a1b95d81c4aef6b3008f65170c48bad28512c863f203f460a3b51e142acba4), uint256(0x16f364788794d72d526cf2f8fc00527a77b4143c258a15a96a80348b674b3787));
        vk.gamma_abc[220] = Pairing.G1Point(uint256(0x07f18813e3273d6ba24eccdd427d483c416a734be1e7baa19e529847fc734e62), uint256(0x15bb0a4ad11766511a4c4342b70b8ed9bc1638aa082455a0ac69504e0ad93355));
        vk.gamma_abc[221] = Pairing.G1Point(uint256(0x2c2f8f862ff48195fd59a77b371d35486ad5b951b4bb33be99d1c31671d86af8), uint256(0x073f23f2f88bdb18bdd253f48321259808fa0faee0504b44b47e91fec3889e0c));
        vk.gamma_abc[222] = Pairing.G1Point(uint256(0x03ef80aa27cd870372624ff9de1415812c557ac1c121c7ecf48efd2a406235cb), uint256(0x079648db75389fa814f858f4bc658adb65b6d09d2c7a4bbb049ed647984986e0));
        vk.gamma_abc[223] = Pairing.G1Point(uint256(0x2c96ed20ba83359434c1b0cb213fa7cbd81db12f073d35556449300e0265f1b3), uint256(0x2025d2780cfaf6511fd99d03c9b7a6aada0848dd9d7bbc983059b3abe07b9e86));
        vk.gamma_abc[224] = Pairing.G1Point(uint256(0x185a780fd8654156ed1077a40618b244766cb6a4d9897e7df4ce76c82ed085d6), uint256(0x28701619bdf03099e339b2995c35d44cd8e12835f13cbed993ee1d0dc608c122));
        vk.gamma_abc[225] = Pairing.G1Point(uint256(0x15bf3892a13b1aefcc89112e4db078979c23ec6a23734a943a486515d4fadaf0), uint256(0x162253cc1d98b353b4e334ec27353631ebccf7bd1c2bad07999852438975976f));
        vk.gamma_abc[226] = Pairing.G1Point(uint256(0x12f8d4eacd765ec936922411a18b86abb632d1aaf0ed82fa2d0d1b72656b377f), uint256(0x08f4d8efcac5dd8bee1904d940fd8021cd20d983892dcf1b04daf741bd15dee0));
        vk.gamma_abc[227] = Pairing.G1Point(uint256(0x11ca08ec795ec514a7240f35936764cd1c0497280ab97baf85a5f16f82e5a360), uint256(0x20ac92f3aa94bd0837e6efb999c708ab0dc468c4b9a5bab21cf0df9d325f95d3));
        vk.gamma_abc[228] = Pairing.G1Point(uint256(0x0972659be8a4ac505a126dd2043be07182e4d4dea3be0d80a776a468f78e1091), uint256(0x18273722cb821bd3f4e6693a2d90b8b9bbdcf84f028b3a4a90d3d3a3f0c8803c));
        vk.gamma_abc[229] = Pairing.G1Point(uint256(0x29f19db48ec0eed91681e4092929a0da1173b1b16fe9937993c975d573ecd298), uint256(0x250f583826f934d05bcb58193a95bcfd834164b23f3f1217e1f6f78e510d4709));
        vk.gamma_abc[230] = Pairing.G1Point(uint256(0x09c29f9678886293894d8e6410a40358816ed9a7328d7fe9a5c60c7af30765bb), uint256(0x070a7a8144cb7d4ea2f90c63e2925ae4df2566d6aa703bf136c3d96b439d4ec5));
        vk.gamma_abc[231] = Pairing.G1Point(uint256(0x0792f702ee9e96912e7718b212ae7d8ecea1e9a83bbc0404db4b3be5fd205537), uint256(0x0e27d77846b3d8f0d14ddf78d06245dc0887017fb6c7bd07e221c728ed4b8928));
        vk.gamma_abc[232] = Pairing.G1Point(uint256(0x246dba8efaec4ad973c8069f76fcacb8ed4a401bab17e43c58e1e7bc36584bbd), uint256(0x22bc0c74102c9f531ad1c2418e304d0ea9740b082cfce91db2714f43cb95ff6b));
        vk.gamma_abc[233] = Pairing.G1Point(uint256(0x08788be3bc4b170e03d27ebb6af0ad91928c29018c08ab55ba9577098a62b20e), uint256(0x17433d51f88aa22bec717824425c3d75dbe6551e09a7344967dbaf4c2f85222a));
        vk.gamma_abc[234] = Pairing.G1Point(uint256(0x1f6aeccdb8685b0704f2347fcdd798cb20e3028d545a062bc62b0b84bae2761a), uint256(0x249867d02f6526352bacfa78128178034d0bace54360bdcabd74fefa08ebc537));
        vk.gamma_abc[235] = Pairing.G1Point(uint256(0x1a342b6bc46290ab56be7b150f4add1c243bc266a7a9384761534e63f50a11e8), uint256(0x0f113b1d0e2d36d87ba0052620f124224a563c593e1e882751e0581d0991f921));
        vk.gamma_abc[236] = Pairing.G1Point(uint256(0x0c1f21a94f60c33697c70107010f23bb569cea707827b88bbb9d28d2577fac59), uint256(0x0115aa3f60642d1887f8e54c6a89a3969668651508d8df67638c7c7adbdf68ef));
        vk.gamma_abc[237] = Pairing.G1Point(uint256(0x01e3afc315d8655ba86d1ce6a680ff8e4261de587a762c31dbd4cb45511c3f1c), uint256(0x01281d8439d1bf4f3ccb5bb5d467a72a9b8356ec60d219da64825229f0999274));
        vk.gamma_abc[238] = Pairing.G1Point(uint256(0x244819d417e66aa9c046e7191ff5b795d898f9d2cc5f90e8b4a432f7c3b4ed81), uint256(0x2d72b4f574e6dda977cd2c4607ece11df1545903e88ce977cae54d377f8ce539));
        vk.gamma_abc[239] = Pairing.G1Point(uint256(0x2fe6a62e4c921675aaa16a1892fae7a0d27237a1fb9dc443ad03d50da3710bda), uint256(0x18543bbc3fdebcd8e364ea3b1b6d6302c9bce6327847bd52aeea5e9acb639805));
        vk.gamma_abc[240] = Pairing.G1Point(uint256(0x2df3b1c344837c70ca5b1dfa04ab47c9debc557d61da38ca07d8be763875699f), uint256(0x1debdc77a156ee6be39ff321e8e53e0ed987b57cd23f33971cc733c581b4fa28));
        vk.gamma_abc[241] = Pairing.G1Point(uint256(0x032ebc11c6d55ac72eca5319c969f2eb91edea6ed85cbf91ba65039df50501cf), uint256(0x23b0c6dd67aae5856a6842aeb3726eb829d40c4463ee69575b7da246fff06188));
        vk.gamma_abc[242] = Pairing.G1Point(uint256(0x1474e87bedefdf8a049a6d99ab811a44cf97ab9885a2706e3f3bea153404bd92), uint256(0x02d200ae651f1050acb74069ff59191d60225dfde67025e324025638e7e66cfc));
        vk.gamma_abc[243] = Pairing.G1Point(uint256(0x07d5dad518be310b81a726233d6af6601648639ae3a2bd49e5781d7716099cb5), uint256(0x29387977a0f4415dce7d330e3d65ec4a7bff9d107e4328eda6ea558d8a7226d9));
        vk.gamma_abc[244] = Pairing.G1Point(uint256(0x0abce2e22b4ebdc7b77620c5efebe097058c7bca5e00a47f9bac895033fcfdaa), uint256(0x1984baae3dba2bb9f5e733bba0345b40420c893361df1a09af2f98d892c5bd36));
        vk.gamma_abc[245] = Pairing.G1Point(uint256(0x1cd2c81cfebf5360ff08ed440308601134d3e20399050e6c4e62a607af7c03f6), uint256(0x0c2a24dac36d0375fe13d945bdb8796eb032a6fa45d83bb587d139ced898e4ba));
        vk.gamma_abc[246] = Pairing.G1Point(uint256(0x07d7922737301c783458cfe6c5a381bd94fb972bf141b9fa12a2fa91cf55b982), uint256(0x004d37dc73642007abf7fbfe019ad1ece025ba1c278a13b74064aaa9da2152d4));
        vk.gamma_abc[247] = Pairing.G1Point(uint256(0x1d85e61a68610236fdc6ada9d93a5fd6960883938042271148f203a35cbe6c0b), uint256(0x255400e0f720e026c2c5fe922497cd04160168fb9b51ba8de812909f6fdbb221));
        vk.gamma_abc[248] = Pairing.G1Point(uint256(0x08e04eabbf22f4581124f77f5083327063ffe6504d886f70af559adcb3a9841b), uint256(0x2d6bf172e1011ebb74108c8e5345d8f9cc38f1b2469da6046ee74fd795e9ed1b));
        vk.gamma_abc[249] = Pairing.G1Point(uint256(0x2d40809878dc4c2874a366ba73b3d64355b97847874e33badc6e812c2b7e638c), uint256(0x09d08e6560e5dd95336d072077ea0e637f0986b0b02b3db591bad9fd75953d73));
        vk.gamma_abc[250] = Pairing.G1Point(uint256(0x2cd28c09434940df3580e11b5797c5c2afc06552b1aa1bad697ea8afdf48fe4f), uint256(0x2a865077e707e2eb59e029ef32f2a8b3e47271de0dc9a35e6c1d887911033949));
        vk.gamma_abc[251] = Pairing.G1Point(uint256(0x1dda29ed0cdcd4a93221757856f6a39cb044f701b0fce31104d4f0d730d1a86b), uint256(0x170340eaa3f339ebdcd820ec0a18fe99feb0c863e4e5679e322f747880a8d976));
        vk.gamma_abc[252] = Pairing.G1Point(uint256(0x14cc30c2072f2880c184826d50857241a056cb4857b30ca24bc34899996691a9), uint256(0x16db21f44152d5955002e5f7a1b42b94e52729a7bb0647bca87cb15e7e748870));
        vk.gamma_abc[253] = Pairing.G1Point(uint256(0x24a58752138584867d3bd80191c59ab5647434375d98f5ab21505132ddccef45), uint256(0x0613edda68251eb2f518612713334b94565bc2543768e391f0743f812bc1a658));
        vk.gamma_abc[254] = Pairing.G1Point(uint256(0x28af95acebc253361e4290078714ec2fb4f68f0760b14f0bee5ccc2f03625653), uint256(0x30264ef44cb2158143530de33224e220b31679cdbf9063b9860b341605c14d29));
        vk.gamma_abc[255] = Pairing.G1Point(uint256(0x1be023473e0fdad8f4017fc9bfa228f4631543f197ea433557629478bc8217fb), uint256(0x1bd8a9ee99e8740873a73e8aacc4468757daef99c77089034cf76d73017922ce));
        vk.gamma_abc[256] = Pairing.G1Point(uint256(0x0359eb55ee5ec7602c0a00218bd70c8ed93abc3641b546f29b1fd4ab5de6d8c8), uint256(0x27136695ddee147c864d845194e4b4da38477c0ff2e08bd7aba385b67f4d320f));
        vk.gamma_abc[257] = Pairing.G1Point(uint256(0x1d6078625f9c5ffe115c485a71be0fd3803ef6f0ae2ac939ec428b9d1a00cc23), uint256(0x1cebfa1a8e24580f9777ed51f8fd2ff71ee0a4e71de9115579262bc2c42b884c));
        vk.gamma_abc[258] = Pairing.G1Point(uint256(0x2f4928c057fb0a40ea0fb49a9f100e29964909425f02f46f3f406f893b6c95df), uint256(0x0b5d92cf8d7961780d5e34660df8bf339cfe48c5090c3a756e85790fe59ce812));
        vk.gamma_abc[259] = Pairing.G1Point(uint256(0x2b6d14d8d2b561977eaca286d9896be75e0f4b6210e0290e8d6f05865e2f19be), uint256(0x1a38600fd37c710a41fd8777e1cf01cc1d8c08e392b82680c3fe8069cbf61961));
        vk.gamma_abc[260] = Pairing.G1Point(uint256(0x21e74b5bd3ddad61a22912cfeee153b4f3bb36993f626d2d75ec7a714dcd54e8), uint256(0x023db2663595ab5f60ded01ed5b078ab04d03e6e4711532ddfafcc5cedd2005f));
        vk.gamma_abc[261] = Pairing.G1Point(uint256(0x09076b572c9a6f0ca341394b39f3cc1ac1987a1e80bf47a50ee0a8edb4840df3), uint256(0x0908489a277d76ecb971d20bb8a93fa144b97ec894287e38798d7f0063c976ca));
        vk.gamma_abc[262] = Pairing.G1Point(uint256(0x0f40431c888336a4058b772ffafaadcc1ce4773f28844c8a4609ad0a17751cd1), uint256(0x0b23c9bb8bbc0aa737f72bf1a8699ed67911ff66630371c17dbe0ba9c8145ff7));
        vk.gamma_abc[263] = Pairing.G1Point(uint256(0x04c6ebdd1f1c316417cf20b32d4fe0659529abf5469b269879ab97949d523500), uint256(0x2703ce08d3c9eaa77fd21e497ccd12a840c30e2e4768246e409761637d4986a4));
        vk.gamma_abc[264] = Pairing.G1Point(uint256(0x09b8908d141c3bbf26a6c25024a00c97f7b3a501794367a1b89cf32acda268fc), uint256(0x1166cfb90a043fee327bbcc20b0289c81b0027fc35ab85700b8403b68d9aa0fb));
        vk.gamma_abc[265] = Pairing.G1Point(uint256(0x07227fc910fc16fa2c9ac2c4ab51dbe67248088f33d9f28c91f45d8983ad2550), uint256(0x17a54c9b92fc3a41c28e017910e1a46f7ea6432af429a78ba0c0cb35f9087232));
        vk.gamma_abc[266] = Pairing.G1Point(uint256(0x23a48fd8f6059ab2009f6ba3502799bd27a3f0a92b6302b74c72b663a82dfbd7), uint256(0x0aada89977b4bad82a06b45816dd424a2c2b3c5754b69f439b8b32ccd2564de9));
        vk.gamma_abc[267] = Pairing.G1Point(uint256(0x26302ad5cb8484d2215468949dc06b196c975d18324b5155ae0e6f4feafe3d34), uint256(0x253fc9dfc12fc8b5c12bfcdb9d6e106b962f7a9e7cbb044d4772eed73a4d82c6));
        vk.gamma_abc[268] = Pairing.G1Point(uint256(0x09ee377edad69ca082e053d8d3432272522c2a819b2f07e966ea0171de45768f), uint256(0x1dfe32e2bcfa3813de80384824fd75f2779558a3cd8f7dd97d3dbd7d74e86393));
        vk.gamma_abc[269] = Pairing.G1Point(uint256(0x2e9a31b27416c502ec537b5a4b9f106c70c019194c79f0637d5aef5e8f7196c4), uint256(0x275c020c9e31a8d83110628fb2ec5aa198a5caae989aa3963576221a05ab5e86));
        vk.gamma_abc[270] = Pairing.G1Point(uint256(0x11b2b5c71e867540561468ffcc5697e8c2b546c0b6ed866cce1f7d1fd5614dd5), uint256(0x0dcd138ba9ffa8bc78c69d78e3fe7c883c756bab2339eef6cfcb69d0fabbd912));
        vk.gamma_abc[271] = Pairing.G1Point(uint256(0x08641affd1c0888f5b923d6d38f8912b7c66e96837347a52be2b306e1ce87bef), uint256(0x09167ee1bfc7b47b54caf53763d27e88b842f9f4f6537490d58e96c98c69f0c9));
        vk.gamma_abc[272] = Pairing.G1Point(uint256(0x2f12ef3bddeab22e761022263c8cf07c00914ee48cb4f8f087d2b227e2054a48), uint256(0x20caf0809141e174d25f3e612b6ecfc2e2c1ca7be17c84338d05dde41cc494fc));
        vk.gamma_abc[273] = Pairing.G1Point(uint256(0x002b788618abac98350821fd8104eaf8b6b16010bb09b0379a82dc6a61871d2a), uint256(0x0cbee0b2be646c4612c313a8916aaab26af9271ba78edde39c0caa55ae89f616));
        vk.gamma_abc[274] = Pairing.G1Point(uint256(0x17720726cad55e0e61e24c69a6bdd67ed70d8ac850b50411268b00cd9d550164), uint256(0x2787425acf998590a217ad45b2d5a2d5636d9de7adbd77eb6aa7775cac934a71));
        vk.gamma_abc[275] = Pairing.G1Point(uint256(0x201e365b2988bd8de0ceea435a679711a857aad778422e42ad6520965292110c), uint256(0x0d10f1337a90e6a8db0d888c214c493e3f1154e6ed158e291b535e648a67dc1c));
        vk.gamma_abc[276] = Pairing.G1Point(uint256(0x0423376d11eff806a17f01c1d62c84c67ff60a9195e126e4cf297b3f20e7b671), uint256(0x25dea42458b6c40f483ca710705ba5d3963a44e52a9ae0008694a61e27d0f0ba));
        vk.gamma_abc[277] = Pairing.G1Point(uint256(0x27ca7d2892dfa4f74db65847ccb0ee7d01a124f2b44a4920bd934739cc036ad6), uint256(0x0511c471e29d5a5730b0b5cc88b67b1f286ee7957c239311346830e20391df58));
        vk.gamma_abc[278] = Pairing.G1Point(uint256(0x10296f1b45399a7e60ed04f640db8f2bfb6bad45f7e7c41f43750662af46251f), uint256(0x1488f671b7d32ba418fed68c9a61a08157ae6640ebef3fccc10699e2b4e4d574));
        vk.gamma_abc[279] = Pairing.G1Point(uint256(0x1adb14dadabbbee0bbdca4b83becead0439315717c23b2154b79e28e99fa4a8f), uint256(0x2eead4109089ff9feee5f666cf7c4ff4cadc48996eb1daaa2f9e99bd2d8d34e1));
        vk.gamma_abc[280] = Pairing.G1Point(uint256(0x0490cd8be20e72124c1a33ed7a1d675e968b958f3bbc2190c9175ccc8454c6cc), uint256(0x0b93eac7e2bc0a72453801c8ed539d2b8e5946649cc057983d38d48668a01e3d));
        vk.gamma_abc[281] = Pairing.G1Point(uint256(0x10169661e9b41cbba8990801e5b56ab9fca58e7619cac5beae86eb932ad54d69), uint256(0x06fec7dc11a66d79ea9d33b17d943956800514ae6fe711ce555c5a4352602145));
        vk.gamma_abc[282] = Pairing.G1Point(uint256(0x11cdf8076bf4b13db800aa96a68a573615431368174eb8ecb373bd6d8eec095d), uint256(0x1d27d744cece29d70f493715f99197a4ade3e7fba28ba2e9c13b373bf9ed472c));
        vk.gamma_abc[283] = Pairing.G1Point(uint256(0x168f7a8aadc6c222ca2a1a967f82cfb4eb56dc08fe6495150fccbcea4cc82b01), uint256(0x0d943fec2af3f69522a70d1fa1b105c68e99e193b453084c8332e7ba5923f430));
        vk.gamma_abc[284] = Pairing.G1Point(uint256(0x27ff61ba373bd252e127c19ce539312ae8b80448a5ef4606fb602835166d7579), uint256(0x03ab1e9878c173cea4b4492f80e204fce8ea3c9905fa88373b328f10908b7779));
        vk.gamma_abc[285] = Pairing.G1Point(uint256(0x1d96e312249cb712f05b42c89846966f1fc0c6ea4f3ef2c68835f2386f6d1137), uint256(0x0480b82ad9b0cc7fd78024acae09f51b0efe379c8038d09feb8308b162d358c6));
        vk.gamma_abc[286] = Pairing.G1Point(uint256(0x03828971897f46dea17bc48d69c1fb3a01310240a50d6bb959a85f0fe03b845b), uint256(0x0ce6319cca9619530395b0c23d03eac6210898e24ccc051c42103ca0dfde1ac4));
        vk.gamma_abc[287] = Pairing.G1Point(uint256(0x2d271575d05cb91444977e8417921139aa35a836c20b687424a1899c42ab98cf), uint256(0x16b09ae206e89642c25e11615a7da785861d510d8c45cc6f0c5866181075c800));
        vk.gamma_abc[288] = Pairing.G1Point(uint256(0x2b066a5daecb905d449bcaca6ee600d2240ca161c003201d12eab4a45696767c), uint256(0x292618e56154640eb6e5536a57cd4ddbd4bf9dc9be76a0035691af3ba022b1af));
        vk.gamma_abc[289] = Pairing.G1Point(uint256(0x000f5ec728d5521d749a7f1485a4405136af1fa5545eafb7719da83031cae9ec), uint256(0x2114258d3baed42973670920b6eb3a656f6d4eda8b994cba1a9b4e9a33a04a2b));
        vk.gamma_abc[290] = Pairing.G1Point(uint256(0x1db430b3857348a1802a778cbe5fcf403483cc3c72b8b19fe9e04918fb8eaf34), uint256(0x1847c6e0ccc8c48ea5da2216424dee53f49f3bf8125ca511161897e195926a05));
        vk.gamma_abc[291] = Pairing.G1Point(uint256(0x172d391f18bcf7aeb98f2c460a1ebde8549140c8295987b53b5b0314fe7ffb27), uint256(0x0b0e17bb9d7b0aec5b053041f8210b0f490ed7339adc2aac4eaa1ef7c43bc22c));
        vk.gamma_abc[292] = Pairing.G1Point(uint256(0x2ec3226a6aaedefe135ffd642b20064e877a959a0d88f27f3a4fdbaf672de7b6), uint256(0x0f7588ebecc7a626275414d6db6de853d56e96b273a3a82acd3f88f2f57100ea));
        vk.gamma_abc[293] = Pairing.G1Point(uint256(0x2cf5123d2125c3617851ddb0ddbd625295fb5d999381713ff9bb7733cca391ce), uint256(0x1d5e600460b0535d687922e7633dc7f77cb128a9eea9d0269d4e1a3a5239f2a6));
        vk.gamma_abc[294] = Pairing.G1Point(uint256(0x0f1ff1d26e2d05609f6153ea1d67372416fd801896c4a7327dbc41e0983b0098), uint256(0x1b5a203a96b153dcdb1c2f6f0e45c6a518392186f559202cc6665248bb7f5d70));
        vk.gamma_abc[295] = Pairing.G1Point(uint256(0x1f0cde37ecb1f0bb9ac7ce79ea423b31a175e063922760289c5e24648f59805b), uint256(0x2fa2d9e5502024c771284898889af1a91fe48ef604a8bbb9747f43bdd47edfd7));
        vk.gamma_abc[296] = Pairing.G1Point(uint256(0x15195c667fac89e4026c1b4140764b2f90d34787d01048c8c527a69a86ca4993), uint256(0x1a6cff1efe7a6bfbac03bcfaf118fd67c864547e7ad1e4f61307bffeac606103));
        vk.gamma_abc[297] = Pairing.G1Point(uint256(0x28113fcdf45aba94d9f48fc9c709a1a6a7c7b6dd5e5dadff4c8eea44251bf5b6), uint256(0x2d8a125be2ffb93723979ee08d663942bbe2495b0cf849e5fbfa50ca8051b946));
        vk.gamma_abc[298] = Pairing.G1Point(uint256(0x073d46eff420b67e0602eef4d150f4d555a2ab2a947651a94d25046d50c9e14c), uint256(0x013aa2758388bcc9f309d2cfd21b94370a9910b921f49feeb863dd4bbb6957ed));
        vk.gamma_abc[299] = Pairing.G1Point(uint256(0x0c49c5901b29b108a41f99ea71f188c8765e9e77f2f793c6c3902e9c54c9fe2d), uint256(0x1505629e12adc8cddc7e6ed02c82d1eeb2db4a2f3e551662d8dc70620fa0752b));
        vk.gamma_abc[300] = Pairing.G1Point(uint256(0x1bbd9837c8677f11edca35cccd70c16d6492568a45e0773891d0cb3d68a08228), uint256(0x010dba0ceea052febd89e89ccb7123042a12636ab3808ddc822552ce8d67f8a0));
        vk.gamma_abc[301] = Pairing.G1Point(uint256(0x04df4f3c853b0d4e6085df9e0d0418919c49d92922b5dc73ec8bc2e2317d5e96), uint256(0x0fed1dee530c34e4116154a9465ae39c6713d8f4ea08a245e470be4ab65a8694));
        vk.gamma_abc[302] = Pairing.G1Point(uint256(0x2502363870cdba8106fd71d48160506426af087e5a9d57e401225680f6e19b4f), uint256(0x0233826c46e2ae899b55de699b18a4f81e31362ee8b3b0c8b18a0023dbab93a8));
        vk.gamma_abc[303] = Pairing.G1Point(uint256(0x04034717933b846ca2a0b6c914deb2ea059316c13b994b197648fa641657b1b1), uint256(0x2f4302f51f19fe7e2fce8b41e36d467115e9a58bdccff8e967c3e43700f7e803));
        vk.gamma_abc[304] = Pairing.G1Point(uint256(0x0e962d5f6085cf247f8e224ea89380699e5d7baac4cd9a738d1dc75c5e95b68c), uint256(0x304e318e012a6d71979922b089f8cb7af739b2d1e6acda468dabc363490ecede));
        vk.gamma_abc[305] = Pairing.G1Point(uint256(0x2ecf2626cf9b906fe0a6bb9668df1e5d5bd6f7f9c8086565c706180e31c4cfc3), uint256(0x25561b4ae5c949c0f394d26a13063a20c3da8965df4d983bfb9185771e7579c4));
        vk.gamma_abc[306] = Pairing.G1Point(uint256(0x2990086c8380e3366c9c6b0052ecd7695549173955f128a54a83d7027ca312f5), uint256(0x041e43ab069560f547090b1181c4b9f06827fda31b4e0fd47988ff47b9d65c74));
        vk.gamma_abc[307] = Pairing.G1Point(uint256(0x12830d6f28d426f940aecb3ab7cd15371a5fe40d679b52a3352044a1c5f0b301), uint256(0x0633e06cd71ed6981f753d264a7f3203108ef0194adbc310f8489c45c0f7f62c));
        vk.gamma_abc[308] = Pairing.G1Point(uint256(0x1583bc5e99e8387efe140fa4608169a9d98857ef25d53d5ad08d97cdbd4a3275), uint256(0x15ee5ae777fc9fd41bd90f6722f4f0da90c92e644a8d4bd212e3e4dd085e892e));
        vk.gamma_abc[309] = Pairing.G1Point(uint256(0x142ce1f0bcf432ddd8c95375b65c4e1e8e19d5eeb580401bb5c8b283765b204b), uint256(0x1239b89ae3a37111a16d456125a7dc44f55ccad0945830f3113e176bdefd2dae));
        vk.gamma_abc[310] = Pairing.G1Point(uint256(0x008055a621f59899b09e0eed75841a783e9eb2ddf279e1ece42e10533dd0c0ff), uint256(0x0f3cf916eea79aaab67a5373c9115052a612cae816659caaa2230f5c4df8553a));
        vk.gamma_abc[311] = Pairing.G1Point(uint256(0x01b13565e743bc5fe569b0df762e2ee3360eeda7d4ceac975401baf71d483828), uint256(0x143f1731ecb06f299fdbcaeb8e9026bf3d311d91f3081c860d3711d632adbe95));
        vk.gamma_abc[312] = Pairing.G1Point(uint256(0x23cd43780e406768d8158ce48532edd24cb1fd7c8fda8ccc229c8c8b7556b83f), uint256(0x02149415a5b153e1d10497e7da04ae67299881ac34b59089010de600f508d259));
        vk.gamma_abc[313] = Pairing.G1Point(uint256(0x23131ceea87cf05b18c4ff806493f66f25a9e61d371ddb6749b111ce6377e5f5), uint256(0x013da773006f21a43a70ccdb97a1fd317b6ba8ae9d89793b56e786909faab718));
        vk.gamma_abc[314] = Pairing.G1Point(uint256(0x0a23a1792f76f4b9c193b1d5a98603b5717d11a8397960a8457ceee40fe43030), uint256(0x2e38dec7fad130af5a55af591b52d3a73082d04864532c36dc5f28544897f0be));
        vk.gamma_abc[315] = Pairing.G1Point(uint256(0x294255d42480b11969e1c9562ea627c4fb1aef977e5140536974c1b091c71b30), uint256(0x1305ee2b7d2564b3c6aa49bf27fac249822b1d7b707eec07de75b1033b99b6f0));
        vk.gamma_abc[316] = Pairing.G1Point(uint256(0x29b7b36e2961a4575d577901972f9b5332e454f0a99cf486eaed451b23eba18f), uint256(0x16dedcba4f42aabde5adcf3f8f5859461743285576eda6d642c2e439f02f1b7d));
        vk.gamma_abc[317] = Pairing.G1Point(uint256(0x0276a1370320c39f3682967b6be0468b99311a46ab1cdca72e24660af1e37a2b), uint256(0x0590d12124c9758793410d1981f349e49d92f2de35c53863d504011397119e1f));
        vk.gamma_abc[318] = Pairing.G1Point(uint256(0x2efc8022329152770bdcca3cf430685094a486adcdcdc9b00d0effa32821c611), uint256(0x214ba4048d1e74b5d90d667972776801aa6ddbc8580ac17fc505a3750a21b721));
        vk.gamma_abc[319] = Pairing.G1Point(uint256(0x2f8b3bd35b62d828913e63b46ff8f54c87cb8d4c0ce673f0504682d2f6983eff), uint256(0x2e372f8f98082aa344247a1addbf6d9f03e01ddc5f5ff74ea7b710db4b8fd54e));
        vk.gamma_abc[320] = Pairing.G1Point(uint256(0x1aa2302b04a15d8fe0c57debe66ae3d88efdaae556106e063be7a8d6854dcbf2), uint256(0x242d88b4c3cad4ac0f1303d49e0513e892f081b61526f5e5aad98e719fb8ce68));
        vk.gamma_abc[321] = Pairing.G1Point(uint256(0x290fbb550f167eea44c4f5b70d4d46e0f7141380a8736c99dce68eae35590095), uint256(0x1661c1083d3df3164cc9d382712614b17134cd6ec41a28e22e655c27b8fe3915));
        vk.gamma_abc[322] = Pairing.G1Point(uint256(0x0623fe5c6869bd78984c2339708caad2965b349c79175ff92c7957577e422fb0), uint256(0x1cf2a98a5eace42e4f5fecb28d65d634e298d74c0ddc1b28e256e06a6f521dc0));
        vk.gamma_abc[323] = Pairing.G1Point(uint256(0x2154aed824f9982aafdae1786f446460d2f97b04a70504f834b281d8f20e0620), uint256(0x21b9bcd77bccae89647e9d4c132f7ccdc42297b9ea317b7dc5d86cc7ae1be3c2));
        vk.gamma_abc[324] = Pairing.G1Point(uint256(0x2b13ead9f6c1fa14301ab056fc8558524f58af34c6d07b8a1411db5f11e96ace), uint256(0x0aa2aa89ce1487400205eaf033a1e17280e276cbc96469bedce9e16354c7688b));
        vk.gamma_abc[325] = Pairing.G1Point(uint256(0x1699120e053a17e2ec21521b8da99dc1d84795f38abaf0bb43c37b0e99be3012), uint256(0x1f13828fffdcb0fc8610380207fc0d9fd06d0a8399964191ac04bcad26261883));
        vk.gamma_abc[326] = Pairing.G1Point(uint256(0x2872b3bf5c70509b7d0b4bd25765b71ea1a201eeb6fe331f5324c4e8b92c6152), uint256(0x044c94747bfd1703367ea69a9cb27adcbaae3e8372c92e349f95674829f1cb3b));
        vk.gamma_abc[327] = Pairing.G1Point(uint256(0x0b7c6b4afa7ad720a496cff02c7a883f6bef216afdf9c517b8e6c03dbb5fd304), uint256(0x1066775d49332dddb4da6df714753f92cf72e0e106733a81028242b340ca6a3b));
        vk.gamma_abc[328] = Pairing.G1Point(uint256(0x1a4a72d463a0edd76cad7d59f8acfcadf4f303398504c12deccb359303e0bc20), uint256(0x0831f89442da43ea804b07ac2ac130a024a8c22e2cf1ab2e8cb4b46a6f36705b));
        vk.gamma_abc[329] = Pairing.G1Point(uint256(0x1ab556495500b6a3e5f53888419c49092a17652c750c1f5f789f9b0f93666c2f), uint256(0x0facfcbee84b9dff0f24df36207880a345077f4b0a9cc477f4e06a405ff19ed4));
        vk.gamma_abc[330] = Pairing.G1Point(uint256(0x1a2bdea35870c3a8775ec1d617a5f00e5ac666cf19631a20bcadaf3a7d10df44), uint256(0x012c8e9cb5d77ac41e43290db0e2eee2092b4816dba0ec6f97f1527dba13c50d));
        vk.gamma_abc[331] = Pairing.G1Point(uint256(0x23bc5c7d80e0da8a198cf46acb8d4192bee1ee958c8035cdfc38f609f7ea6f75), uint256(0x2f97ffdd3272a0f50b70c50e69e982b63d4a594fbf912a783475ea1559a9e45d));
        vk.gamma_abc[332] = Pairing.G1Point(uint256(0x1243193e7a8a4673710ccc9a162e20aa366e3c3a023e61c3020a72eac955cf7e), uint256(0x21f6a8674cc39ae4068f6ad9500be40e9a2eb22889225dd95e260de9adc7f337));
        vk.gamma_abc[333] = Pairing.G1Point(uint256(0x169819cd8d45f81b8a1a7e002bdb45626c72eaf2bfe8ac45f3602f8dbc50421d), uint256(0x050d1459a3e862eb4f147ad66e8629b51ddfde08e7f7cedc3db6c2afb2e9f732));
        vk.gamma_abc[334] = Pairing.G1Point(uint256(0x00d6b528bcee36672471a660c94e11e915eff12f11b9444dd72623260dd15279), uint256(0x28ad5fa1bf9af4a8cfd5169a0e16493b4f7fb8ded48a131abf3a405625ef5b7e));
        vk.gamma_abc[335] = Pairing.G1Point(uint256(0x21eba1a6da215988f85e0ac3aafb551fa4dd0b6e3533d3afea21fde64a19917e), uint256(0x0008a1a3b3a01b4728aeaec82ccff3c7cb04858a9283a8cd8ec248e3fa787479));
        vk.gamma_abc[336] = Pairing.G1Point(uint256(0x103e53c7a6f322f792afe7cbc747f41d6181432826ec22222b7f640eee256eed), uint256(0x2c726575446190739bf2b7589e3d23b91df590f0faf0b4949b8397b89cf0ec23));
        vk.gamma_abc[337] = Pairing.G1Point(uint256(0x1e54777746244314b913893309642506e8d96a681aa735085df415a7fab4e6bd), uint256(0x04538abc6698f07920107f3e839ae1f886d0ebb54f10fb19f2241f7a3ee13c34));
        vk.gamma_abc[338] = Pairing.G1Point(uint256(0x1d574fa826717acd42b84d8116273de16c748550bcdbe6fbe4a5449d51a3dc1e), uint256(0x17f2ad3e5b08428b2fec8e7c4b243d78a6c86cd32477ed4c498b60ae63211dcd));
        vk.gamma_abc[339] = Pairing.G1Point(uint256(0x0aa03e27c54420559e363ce2c9ab018de2a12f281dd6a66ee2d55207e3e5097c), uint256(0x10c3e2a156cf98793771ccf933e5b51b1df24fb4fb3a17caaa449b39979bde29));
        vk.gamma_abc[340] = Pairing.G1Point(uint256(0x16589542d06471c0a95666f17716d03686ac1176e03f8bdb903462eeb8169ded), uint256(0x12cf7654a383e7e14dfbc4c01525b05f3565aebb1b7e346eac2dd69871d3eb9f));
        vk.gamma_abc[341] = Pairing.G1Point(uint256(0x203567d50394b19a00c71717f6a47e56c8821b9db11ba5efc85f2f9f3e71f4e4), uint256(0x29961090647efd439f8353f7ee47deb750767efbef3b6b16c6271cfb442352ca));
        vk.gamma_abc[342] = Pairing.G1Point(uint256(0x2317b67a34de5ee11a7161e7260bab6c064c36f26faefe849196b47844732a1e), uint256(0x0d1585fceda532ac4a9854208b99ff422ab9de97145fda42c880b50ec9a7377b));
        vk.gamma_abc[343] = Pairing.G1Point(uint256(0x229b87799abc3926a33b9ff5e726d28a026a7d8da945d90b78126a9db1f64223), uint256(0x1a5063b6b14829b2f6e72b7fcff858c899675e698366f5e5433ec756986c61ea));
        vk.gamma_abc[344] = Pairing.G1Point(uint256(0x1e91e6b9569954eb489fe30ebe0864787e28520853321970632e4fb4ff0bc6ce), uint256(0x2398f04866b518f7bb5d7e43c973144c3e13dc2aeefb99452c1665414a06c276));
        vk.gamma_abc[345] = Pairing.G1Point(uint256(0x1d9234bf9802072d283c6b55d9909b5f4a880ae5ce499c6be62b492dcdf2912e), uint256(0x0a629cee8466fcbfc0e34f674accc34dbc1109868054891f9a4f69d4d8e575c0));
        vk.gamma_abc[346] = Pairing.G1Point(uint256(0x12debed95abb8fd2c66a1717fb4f93d93d946efc70c8e716246a2f7066c35b54), uint256(0x06048888c208309486a1f9b11edaa90b7b22bdcf1eeaeea60873c51842787ee7));
        vk.gamma_abc[347] = Pairing.G1Point(uint256(0x2c6d44c977592aa609482a19067fb972387277d02ab76936799a457dc89ed31b), uint256(0x25f34c0a05f1d8bfd5fd2baf0a27cd7a3128921e7ce7ea35d175dd8ccef953b2));
        vk.gamma_abc[348] = Pairing.G1Point(uint256(0x2017c9e061b2eb40a872f12336443284499405b7e177c803274d6b211c0cef96), uint256(0x14ecbb6dfbac57a69ef56184784f9bf901899ff9518008494e54879106574264));
        vk.gamma_abc[349] = Pairing.G1Point(uint256(0x26b6881da6d963727f3440aaadbfc488dc53296e465fb14c138c1d8c32695071), uint256(0x1785fbaa5bdcb475910b216b1d6cfe2a63fa481050d9c91f4415e0109e44d580));
        vk.gamma_abc[350] = Pairing.G1Point(uint256(0x19661b51a5a90b9350995dff9cf386b6bc09808700b9e8a36a57f4a09f61778e), uint256(0x1b5ea005762d3e782924e30e6261d3a5af4ec4ac3ab11d8cd473075382e13993));
        vk.gamma_abc[351] = Pairing.G1Point(uint256(0x2fcf83d59caab3440724d4c19be1d68b89effc7995fe8aa66ba3474e3a3b9da3), uint256(0x2bad03f086a7e738bca780fc51ee87b5729eccf469be853c0c912d0bb221e450));
        vk.gamma_abc[352] = Pairing.G1Point(uint256(0x1af60d5837640aaeb87a117dcbde03d9a3d6f9187dd1bd3896d3655cde30f34b), uint256(0x2ba48e4e9eb18443a48ea2730181fbcaf2092ac2177f60740179f18210c969bd));
        vk.gamma_abc[353] = Pairing.G1Point(uint256(0x070ae456303c7bea78aaa1dc5080db9c80f34bbdbd268ef931d1b7b05676a7e9), uint256(0x09e623a4009e1dd668de653b6d6b39ff3c33873f8a7166746b1a45b8483d4c57));
        vk.gamma_abc[354] = Pairing.G1Point(uint256(0x1dcb02b23214ecf327fc37bfbd9a1c1991e1f309a5e75fd34d29e2f2066f7a68), uint256(0x21aca73745a1374e94875ff2406fdf2d209f98b3247351d69c8c3863c640ac33));
        vk.gamma_abc[355] = Pairing.G1Point(uint256(0x063a19786ed5c5203375cccf0953a416db0a58168e88e6c466f6c5afe9d50197), uint256(0x21fc078b4ac0e4d602d0533be1ea8e4ef0c3e0215d13c71e885316fa74600a02));
        vk.gamma_abc[356] = Pairing.G1Point(uint256(0x1dd5d12a2a7e0b1e64dd0878391ca20cd0de5ab7cc272f71c9b14c3ef8062267), uint256(0x0df2ecd742722a90351f0a2cda8e20fbe9155439ebf3cf0d873c51f6e71186b7));
        vk.gamma_abc[357] = Pairing.G1Point(uint256(0x0a29822a1d5b9bb9be2bc17c5476d4accebc5f8e30e94b79333b6c7e80e98155), uint256(0x1fb42427b49c47575e6c81dd65cb826be591c963ca11ebada636481c216d1295));
        vk.gamma_abc[358] = Pairing.G1Point(uint256(0x164fc589ec2efbb420641e1d6b1d7ca61ecb951af8ab3ccc826ee77ec217a46b), uint256(0x02022edddae45bfdd0d07dff1bee2882e3f189087387181abc9302919146d5cb));
        vk.gamma_abc[359] = Pairing.G1Point(uint256(0x16f2f6b5ed1a81d1945027a15987e664bf6e56bed899d49707f00b1a5caff1ec), uint256(0x1049ab76cf436d09c764f61e52d8fd2edc3206ce826306b1010ab3db833c6ac8));
        vk.gamma_abc[360] = Pairing.G1Point(uint256(0x30036c01e2af1bfc000cb40ca38b975d970add9e59ced1c1561ba88fc8ac172e), uint256(0x0d15902e83a85253cc7169e2a3441d459216daf8e9224b4ba85029423d2a1ad4));
        vk.gamma_abc[361] = Pairing.G1Point(uint256(0x0c6fd0b5fae6b4017231be2325efabe723947ed0101eacc4225d6ec4ef5abb5c), uint256(0x15e0ba6704d55e713b63cabe894377a222a322147dd5ba16d0f9c7029373856e));
        vk.gamma_abc[362] = Pairing.G1Point(uint256(0x06ac6e36cde4a059c69f4713dbd16793f2985991bb9279dc65b126a31cd64876), uint256(0x15be3fba4a062ae0094adc723a955cac31a22a0480b1ed560426a685e2731112));
        vk.gamma_abc[363] = Pairing.G1Point(uint256(0x17b206419598769dd448b8105831dbe5c1e2bf108d734158206881bf70e68e9c), uint256(0x0e447a35e4487d271c9e166beeedefc194750c2b55df3b3dacb466eb9217310f));
        vk.gamma_abc[364] = Pairing.G1Point(uint256(0x2a48e99661d91c431958e3c0c3e8b3158a4f379f940e6e266076803381b1e7c7), uint256(0x084172323289bbbd89915ae9ce9c74b89f36cf18c5aaffdb314a81aade2797fe));
        vk.gamma_abc[365] = Pairing.G1Point(uint256(0x0a9165ab761c59114417d5efc7ded91aaf040e6113b3cac0efe40cd33a48bc01), uint256(0x0e2129b6bc70351ac584b83d4b1e3a493f43fe44e17982bb1d8f70457cb3cd1d));
        vk.gamma_abc[366] = Pairing.G1Point(uint256(0x20a2bccd82d4beb29fa4a4f67ee271fb90cda923d2a86fadeb3b82f67ef0257a), uint256(0x0b72af079fc8ea8d0fc9b1d72ad1907892b96b2f21f55dd090219181bd90b3f4));
        vk.gamma_abc[367] = Pairing.G1Point(uint256(0x1d7775019ef37aacaeec782cac3a927b805f4155e47ef4db1a9c994b99670f77), uint256(0x1218ed8867ba221242fbe1dbb61363001b420eee68164a90b1dce5c34db30356));
        vk.gamma_abc[368] = Pairing.G1Point(uint256(0x059c5c22cbd9f0a326d980aef1d6b55b7eb34aee69885bfc3a4a012b8f3183f4), uint256(0x1d2d305c90af8edfd5d962d2d9f8336f984c3aad1a01b5624b5d4e7d5df37c71));
        vk.gamma_abc[369] = Pairing.G1Point(uint256(0x1ac4427c8b60a2bfab0e8cdb0585ec719a5c3f12f4a8432483079bf142473a16), uint256(0x14adafaa7b3307d6fd9e7557632eecb553195947d324856e968465d0dbd2356a));
        vk.gamma_abc[370] = Pairing.G1Point(uint256(0x12128009364947703636de86ffa3dd8915a296ba4fa142490ccbf1c40c5a7366), uint256(0x1bc7cf169eb500e8075c6accc7996ed7897019c2d26cea1a8e578742577b5623));
        vk.gamma_abc[371] = Pairing.G1Point(uint256(0x255c636ec01d6ef8c3cce3019663fe45add8d5da69be5546bed3fa02b17da7e9), uint256(0x15cce94f348052f46fc6e5f10a457fd6d96f9bfb7040eb464ac91a02f1cbe3bd));
        vk.gamma_abc[372] = Pairing.G1Point(uint256(0x0d267b333fd234c4fcfceeff88a3058c3b863749caeb8f938e752b3e3bea8bba), uint256(0x037714b5dccbcda8079a63301d59ca5301899f4e7cabc03e954325756277eaec));
        vk.gamma_abc[373] = Pairing.G1Point(uint256(0x2267fc2bb7a7cb0e87722e58cd21dfab8ef372218b8ad3e185abc795fa5e095f), uint256(0x2ce952fdb6e2c447020d90a48e52855d64868f6b29118cfaa1a60c64290f9371));
        vk.gamma_abc[374] = Pairing.G1Point(uint256(0x09c250220d35e18f98b35f127c5e8fad448acef08384f76b9ebc87bf682fe473), uint256(0x012dbabfecf3c15c0063dee1f24469813940a983da91d2dfb3dd121a576a8a8a));
        vk.gamma_abc[375] = Pairing.G1Point(uint256(0x2b14b23ea11016467eb45282e4197a68c409e43fba401b465475e90e65f88c28), uint256(0x096b49425fb14b4de0b79ee1aaef7801cd7c96253877693f85c1298cc2dbeb16));
        vk.gamma_abc[376] = Pairing.G1Point(uint256(0x1ffd9af98af5d3f6a12342ce93d932511ae69b7ed93da48a7e50880e2cf37207), uint256(0x2c93b44675d5773a4ef3c07b5e4757e5015eb24881041f902df2e249098ff057));
        vk.gamma_abc[377] = Pairing.G1Point(uint256(0x1bb6d9a46c760168491057355a019b583456595a2573bef3b94b64e20e7557ca), uint256(0x217aeea79a1059c2d947828efc06deb6d027b2865bbf640a1dd64530fd22faa1));
        vk.gamma_abc[378] = Pairing.G1Point(uint256(0x2f376395f04ef547f81be16a61d669d4db86bc9eb33a97534d40b3185096677f), uint256(0x044d93caa2f74372d5af4baa82074a74cc4eb5861f8e548f371559cdfca59d4b));
        vk.gamma_abc[379] = Pairing.G1Point(uint256(0x28f648a008372fbfd873af3a6cfb181c70d7987e9b89249513734c73e3dd2f6e), uint256(0x0c8e63dd8d051895b7981978333ced400634740f56d7ccc2737684c0dc41ba61));
        vk.gamma_abc[380] = Pairing.G1Point(uint256(0x04927c83b970bd594fce6fcffb1d322e0f3c06c95590dc04b4e307397566a11a), uint256(0x254d2bb031757fa9bf82abba3b56ab62faa4bd6a921e13a1536375cda9e9d1f3));
        vk.gamma_abc[381] = Pairing.G1Point(uint256(0x06b7695d006e7430e500052284825254e74f0fb478238a2a3fab3b2e238bd256), uint256(0x042c126e6614a32312d4b927bc5bc407f5a97ca62a0ef7cd76d369ee286f26d7));
        vk.gamma_abc[382] = Pairing.G1Point(uint256(0x115666267ab7a600ca5b471761e18b14d2f876138f1be12c152db885de593064), uint256(0x1e27180faed8d4e5521feee8b758c73f170e5824d35f67658cea462cb1ba6bad));
        vk.gamma_abc[383] = Pairing.G1Point(uint256(0x035ccba927fb118efcd6dd656ad5a453d03e31fe5b05b69e5bdb00ddf681ecc2), uint256(0x10322b812f83a31294a80d3308b1a0803c3e14ba5131249b0b6ffc1812411c45));
        vk.gamma_abc[384] = Pairing.G1Point(uint256(0x125c25e6ea186461a84d0d954d0a8bdd3f08d7da40298c86b0e5bf44820d4d93), uint256(0x2dd79547fa42ae14c969cf1b4110990d72e1cb27a337dd26ec386a1cc6b196fc));
        vk.gamma_abc[385] = Pairing.G1Point(uint256(0x213b3020446f897a9d53a40c83f38ab0e99c33b3f3f0b66fbb961c24f949fced), uint256(0x17d14583746ca2271e831f146d645375db2d43849f688e88dda802309da623c8));
        vk.gamma_abc[386] = Pairing.G1Point(uint256(0x2fd6cd398048b34776952292a15f158bbd76f0b24f88a74dc8284cdd7ccd7cc1), uint256(0x161c5b2a86369c2747225c6d572b3895a4a6f65251d5797f178cd78316abfc5d));
        vk.gamma_abc[387] = Pairing.G1Point(uint256(0x038b2ca6e02bebca615de0c5ae9ee42c85f9d6259e05b3835643d860f2b51edf), uint256(0x2b4f54f91998a6243302ab664482f7552d762e07ee1ff94bb96a760d2b5fa018));
        vk.gamma_abc[388] = Pairing.G1Point(uint256(0x2be4c1fb565798f3cbae896ce174ee89d349dafb5135bb09f7b0204242aa3dc7), uint256(0x0bc864fe9f3a3a8ee1b1f51a09f78c5a6532fa1a257769ab4445c6799661e7cd));
        vk.gamma_abc[389] = Pairing.G1Point(uint256(0x102d101f609aff98b61d774d841e3334ee50669522d0a7135754f9611e3cec63), uint256(0x0147c0f72250b36b2011cbdf6aa7a32e58c679c7179647a80afcab220fe6136c));
        vk.gamma_abc[390] = Pairing.G1Point(uint256(0x072a02cfd5ae64357212ba968e59c85b35b0ecb7ab061a62127f96c901271aab), uint256(0x0ebd522eda4488c2b11d8e563cdf219483455222e5b6c293397fde0ab354887b));
        vk.gamma_abc[391] = Pairing.G1Point(uint256(0x0d2ef348da760db7499a17f4f57b8fa178f2b6a8563f6ae498aeb7b213a2d9df), uint256(0x1a5ec36bfce5af9e8cc8b308d36412cff8d19014e96e406b0c0fc337d0cefd1d));
        vk.gamma_abc[392] = Pairing.G1Point(uint256(0x0192f2e7081894c4b96ff3d7b53c5cfcc1704dc3f867e26fac3d4339774995b0), uint256(0x1eba657d86b23707d5efde87e6f453666317cd5e3c7c5161c490b377ed4810e5));
        vk.gamma_abc[393] = Pairing.G1Point(uint256(0x052c6471044da521d4c202ba5d683c6bca782262dee82b338b006c9ced9927b2), uint256(0x132daa41fc74ebfb23a66ba2a5c8ab31e43a27e5abddb8242baeb68c7cd8124f));
        vk.gamma_abc[394] = Pairing.G1Point(uint256(0x2e48a632621def8b278435b8fe2f43bbff8d668b908f653bdaf783255cb371d6), uint256(0x033d365ece53dafd2ecc62d67b8150d7c65819092a29bb11e0f34a910b52eb9c));
        vk.gamma_abc[395] = Pairing.G1Point(uint256(0x0acbb2265685756b0588be78b4de17a95750a96eb04f6312fc5f05d203edc0a2), uint256(0x0495be69aecefa9c7a0f6d9b2552abdc0b09576c64e3a9ff37bb46e572a9eea8));
        vk.gamma_abc[396] = Pairing.G1Point(uint256(0x23585d730416c1ae479efc2bcce3c4387deaefc6a7b9e1dd97160bce74c43be6), uint256(0x10cf4e7db4ce5e67a3d035f3e4333871f76affe9dd99f8c3423b37d36b59857b));
        vk.gamma_abc[397] = Pairing.G1Point(uint256(0x05d67505ff41835db875f816205a36480d5163d8fd17645f642edf0930ba395f), uint256(0x0de03226d11f1720889cbcce24404b7bcd10ce774446b1e275dcf2bc54592f4e));
        vk.gamma_abc[398] = Pairing.G1Point(uint256(0x253c93d562fef4944260906e456f8f9f61b0ef1ea1f9a692cf1bce1455d070eb), uint256(0x07d70643d609a51f6607badbc8c278e2591cbd826e837a3bbd5344813b4216a0));
        vk.gamma_abc[399] = Pairing.G1Point(uint256(0x2433f7b2cb29875381dc98d22fe5fbe4af1327f244e620c6da1d14b44dec0a05), uint256(0x2e90afc87504622bd7d942c26c8241467e32389f26e6f473e11ad77d0a495120));
        vk.gamma_abc[400] = Pairing.G1Point(uint256(0x0f013c9199746219c54779deaa3dd98be5ce8ae58103201157841a1046885fb2), uint256(0x02c9f4a3e6ffb8e9c8a259807842e695ad51c514bcdf4777276e6cef729bf85c));
        vk.gamma_abc[401] = Pairing.G1Point(uint256(0x0a487374213e64d1da225012d3cffd76768fa7b84a7ce320e204d3f95565cf89), uint256(0x0d7cf17e89717dea498d2c533f47cbb6984ef1584d0c0c14b8e6d1f2667ad18c));
        vk.gamma_abc[402] = Pairing.G1Point(uint256(0x02d43bf6940f0539acb0f23e24b3d258d2d7a12f230ba5232d0c48a600a7a1a3), uint256(0x1e0138269092eba83333ceaa80174cee24f0458302da6d773c517dd3cb77d0b6));
        vk.gamma_abc[403] = Pairing.G1Point(uint256(0x13a9c2c5fa8e06526ca7ec25392b78332f04188d923ac5acefbbcb7c01a5b666), uint256(0x2792a4f92f0c6c13d039345e545be100c34a1630e58a405c3aadbcbd54cf2ddf));
        vk.gamma_abc[404] = Pairing.G1Point(uint256(0x195660d6eca17d28de4e2b80f62dc8bd51f63775d767eda9f18a0d74f6290776), uint256(0x1e19b186e0fa8b85797c073e5d46728bc02d8f53072a9d1f781a9b9e60f11dcc));
        vk.gamma_abc[405] = Pairing.G1Point(uint256(0x287d06ed780568988569f2491a92e0736c6dac5c0bc288bcd5d9905d1deb6669), uint256(0x08424acc53ffe04bd7b1942923106a512589c5e3b3a0e68920673d2429a3e3af));
        vk.gamma_abc[406] = Pairing.G1Point(uint256(0x162bd4838a445a5d39b273a46561f1fc507350731bca43143947b5a30f833d82), uint256(0x0e612ed6ae9639e398c02656bb9aa22bb94b25431d80a6fc4e1c3dd9b7ecd905));
        vk.gamma_abc[407] = Pairing.G1Point(uint256(0x239e44f05af5d76ee5198c6a84884d8296bc392bf7426baee6c1fa7a6bdc7c3f), uint256(0x1eef6345ca5ea108b59c6cf10df8f66eed1805d24b26c0b97625a72b68953354));
        vk.gamma_abc[408] = Pairing.G1Point(uint256(0x1d948654178d2f7b294c963c714a0b341df0175d6b1e22440687f4b39075769d), uint256(0x11c63b732cae4f60f3cf38d097589f8249aaa8d629a25e1cce33ebafcac0fcef));
        vk.gamma_abc[409] = Pairing.G1Point(uint256(0x1b12f343a937b301aa5b0ebf4f53af96f9bf4116dfe39d79affb1e1110613b3e), uint256(0x0f264c109639199fad17284a61cde1bf23f1dc5c4a129929af10c0321f0946ba));
        vk.gamma_abc[410] = Pairing.G1Point(uint256(0x2d4c5627016e4abb4d29060c8d830840145f80a68ff6ad359be6376855a032bc), uint256(0x0e64b9475dd94572397d73c9d3488026c0540ca7b943b718762753ff1a161962));
        vk.gamma_abc[411] = Pairing.G1Point(uint256(0x22cb3096b8f93c782626ae77a804f06657fc14df84490e341c33e34f7dd803fb), uint256(0x09422f27d3ae42d843148f9c9a89a343e744ae71d164a594e3d0c028f8b15f3f));
        vk.gamma_abc[412] = Pairing.G1Point(uint256(0x2993bc7fd9f9d9e81e1be31c4e8e3423c32f0997ecccc79159c15952652ad404), uint256(0x149dc084e1a0b6a44f07c653f90955d0729cc726faa144879e9650bd42eea1da));
        vk.gamma_abc[413] = Pairing.G1Point(uint256(0x13f0a3ca8e752b34ce1e02cae748fbb05cf08c107b1270d93119ecdfd1dec173), uint256(0x1832a25deb1d140560227520aa77032c6899222d8911c93a422ccd29eb185978));
        vk.gamma_abc[414] = Pairing.G1Point(uint256(0x202edd55cc30b0f04abd50e27db9f283a19c6d1d989705b9eb7f6dd399e22257), uint256(0x10dd905ae8c2c7f224088daba7189d1c30a9ba8b9ad28bf1c1557f1c0676791c));
        vk.gamma_abc[415] = Pairing.G1Point(uint256(0x2e28cb4c145da10f87c36a5d4a55d5050d2c2c27b30b93b2ba7aec81b73d7d67), uint256(0x0c37647652f751ff384a8ca5bd8a52561bd59caaf6f5d17aace75c119cd65cf7));
        vk.gamma_abc[416] = Pairing.G1Point(uint256(0x128fffa5cd592a15134c581f2dd97c5f5205db2ced723c845a743c372106af7b), uint256(0x2bb0b9ef31ace90437013b10b0609d6e641dc4efba1f8efb98bad286ff2920f0));
        vk.gamma_abc[417] = Pairing.G1Point(uint256(0x0b129a00f779a11f4581a16812100b4b33956df792cf4bb90ad68d7001ac1e6c), uint256(0x20169d847e4c12467db37b28d50084a51dff2bf5f70e49278cabc89eac0effc5));
        vk.gamma_abc[418] = Pairing.G1Point(uint256(0x0a5ffc13eda5a6893978e79f7c0d68bd068a625596ec33c52dda0ad8f58e4c51), uint256(0x2066c3e374a26cb56c74a29b6509aee777bc7bce32264e8ef7c5f3cca2cb0ef4));
        vk.gamma_abc[419] = Pairing.G1Point(uint256(0x1311a58ffdbe8d782e00d295eb948b8282c509abf95de1d28fca77d694df63a3), uint256(0x13191ec5382b4c659cfb7c88c1ee7595ace271c06846ec25e71dfcd03360cd5c));
        vk.gamma_abc[420] = Pairing.G1Point(uint256(0x269d97d7f730306e7676b7a8a1f2d85707f0a89c73c69c2f0fb3cff5c1037326), uint256(0x165e4532523840be053b4793eb73df891fba6a635f022e20da4d9377b556402e));
        vk.gamma_abc[421] = Pairing.G1Point(uint256(0x29b8e1804516e953434f254065970334691252917ae028408106c073bfcc3bdd), uint256(0x170460140d2913cb88b9c98f8f4ddaf0d3fadce8f767493c2f489c7f304fa989));
        vk.gamma_abc[422] = Pairing.G1Point(uint256(0x27320c56eec7d3a463567a66df904b4c8b6fde0b82f12e67b7cf7bd78e8a92dc), uint256(0x1c4085afc5fabd4aa6a6bbfcc9b65efdd4d44e1bed45930206d62194e70fda66));
        vk.gamma_abc[423] = Pairing.G1Point(uint256(0x2ff2cf66d45f25948fed5c6d609fbbfceed943b3a9f549d88e1f895171ab0dc3), uint256(0x21873e2a2930806d94080b3d2fc8280abbfdfb48f3ead3f06874821698e54f80));
        vk.gamma_abc[424] = Pairing.G1Point(uint256(0x28aed6cfd6d4da05099de0ed1697a7d1657dd2f013f7795c9f3b4414fcacdd40), uint256(0x2affc4bc2d8f310c9ea6e28583a026f909fdb157a8d00134bc6eb0aee192ff61));
        vk.gamma_abc[425] = Pairing.G1Point(uint256(0x2399500cbc46699b7729e7ddb50e326bec41030626b6d832b69d793c554f9d2f), uint256(0x1a0c5a696b4cae06d3919c6e89230ed22beb538daefbc714b47b3f2e67b5e38e));
        vk.gamma_abc[426] = Pairing.G1Point(uint256(0x0ab981466012c8e4b70e5a9d1cc378ce0f2f7aa888a0d806a0226dc3289d6200), uint256(0x11bf863657130cc77102927ed4d5cddb07ca1a42711a62978adf89e0878afdc0));
        vk.gamma_abc[427] = Pairing.G1Point(uint256(0x20970eb6ecba65c25e818b8413ca3c32aa39425c245a032c8cb1dc5d81c0f7ff), uint256(0x22660ef659f9b3e2d910b8943ee299f8d9d8f7193b09745a4baade2a7ebe09d8));
        vk.gamma_abc[428] = Pairing.G1Point(uint256(0x1b81d1ef5475cb836ee53676081496fe2763428ec063d65735b0b30b89cf7f22), uint256(0x276342958a97ef5867e02f5aec39f54609408e4432306c3446a9225c18f0871d));
        vk.gamma_abc[429] = Pairing.G1Point(uint256(0x2f1fa8359f0e8747a9c605d537eb8ef1363e9fbba98b7f9aeb0db13bcab8d1e3), uint256(0x04911edf123d3796142ba6f59e6139ce226bdb36a3aca3590aac4cb931758e9c));
        vk.gamma_abc[430] = Pairing.G1Point(uint256(0x2323ecbe61e036efe8d1f6b2bf8d30e026c694cd69a4bf27a005f05ae0df1980), uint256(0x30592650437b91ffbef3b0e637e99227fba0646ca7ff72e6407158ba244b8e25));
        vk.gamma_abc[431] = Pairing.G1Point(uint256(0x22054c396426745a6ac86dbb55e2bc192a869aaa9dc1190eae974db3a81ef5a9), uint256(0x2f9d0db02b6774f388df7e21c464b712428d16269259d7e285fa801b27a23e63));
        vk.gamma_abc[432] = Pairing.G1Point(uint256(0x056ba9edd941292ec228cc63409aaa212655bbfeb74365878f5b2424d4378e1c), uint256(0x17b88822f7834fa6ff5fec4ba514db4c537dac5c023433869b736986d3dd74e6));
        vk.gamma_abc[433] = Pairing.G1Point(uint256(0x180ff5b091bbe58eaf1f1939eead8f670b0fa07898ddfcfced6972702662da7a), uint256(0x123cb68cf0304ff3d765d4a940e4a6cfce7129ed1ecbf613be5ae38532a5a1a8));
        vk.gamma_abc[434] = Pairing.G1Point(uint256(0x1bb12f9771d8886ced967bcbb66a653223f5966145cd4050edab1d695932ea0d), uint256(0x10eebb8b66dd8b8282cfbab07124f011067718a1bf4109eae3fab0098e68fed5));
        vk.gamma_abc[435] = Pairing.G1Point(uint256(0x2fd059f01ca7350ff24f682692c8e030e1c8527ded898bbd7b99c6a05d732adb), uint256(0x22b46e5d166f5c8df8c4d66556afc5aeed15cb8dce790c072bff19720b45ce4b));
        vk.gamma_abc[436] = Pairing.G1Point(uint256(0x0862c4969587d130bc7058b8a91471f7817191060fae8da6eef7a264aac7cdf2), uint256(0x2670d872a344c96610e37f85c240aa7581bd44cc15069cdf04ae00826735d5d6));
        vk.gamma_abc[437] = Pairing.G1Point(uint256(0x06962224da622f59b71afb6a4a26afeadd571928b73d27bff4f65581595801fd), uint256(0x14e66aefa7156bfd7ccc69893f306f0171c469323b20c9d4848a71626bfe32e8));
        vk.gamma_abc[438] = Pairing.G1Point(uint256(0x2832ec564be8759177003705ae9388be43026491181883557e399f369cae6b48), uint256(0x0ea9ce85829187b4c6fe640a3802b733a2bb6f6ef1f04a88c08c75e8736099a9));
        vk.gamma_abc[439] = Pairing.G1Point(uint256(0x10d51f6bb40430f023589781c2c64e49c6c3463dd849e2d3bc21ee479f4129d1), uint256(0x0bace17e44403d3150e7e390a6114e4e3760b667c4b1919f677dc94e9bf80eb4));
        vk.gamma_abc[440] = Pairing.G1Point(uint256(0x09c1c05acfbf8ae94c30fe811b91144765e89ea8f37e7e6a567ceef8336dc03c), uint256(0x102306456020a5a1aeac381e1fbc5f2e865449969c9908c808b87b9ce21c4aeb));
        vk.gamma_abc[441] = Pairing.G1Point(uint256(0x17d7a7915546e496e9ccfe08f0bd450e356ecd88d83ef08b8c6f00dddf299c28), uint256(0x1e1fa8aaaf823f4141e586ea0c5ac36e7867ee625b9bb8a15dcfbd4297a72e5b));
        vk.gamma_abc[442] = Pairing.G1Point(uint256(0x0f289c276e7aaa105e319744e46ebf747042b267563a4fa9505ec0fc696de7ea), uint256(0x13bbc9bc1b0c308359037922ad041b0317fb10f6e972ee9eff77d6fb8b9fc583));
        vk.gamma_abc[443] = Pairing.G1Point(uint256(0x0d71c4610e4d3968aa6c80ae2df3202fa04c78e173c45346eb0bbe60f1cf1c51), uint256(0x1ce8337919100fe7662eab6800cde76c1104dca73ccf42c055a21504883fe897));
        vk.gamma_abc[444] = Pairing.G1Point(uint256(0x06fd4ff75c035edc22424b6224fbeb907e12c00f998c4653fc5ebdeec29c7337), uint256(0x011f9868f5c6daa50bda327d2e670d677f6692ea3210fa136b5173d2033c4fac));
        vk.gamma_abc[445] = Pairing.G1Point(uint256(0x0091a9b04f5d19c6fcfb73abb259a763e3ebe2fb34d5b53f4172ddddba692d6a), uint256(0x070ffe84f1601a2ffd8243a49046f6bfca46b26e94dbd67d6d85a48a38f6d01f));
        vk.gamma_abc[446] = Pairing.G1Point(uint256(0x229ab8cfdb9b91765054cbd9a4b3baefcf6f9dc5cda1d187fcc86c200fc99501), uint256(0x2942b3555bbcf5f88dedd65d37cbac048d1e2c4ed60f3f52d7c71b2aa5091286));
        vk.gamma_abc[447] = Pairing.G1Point(uint256(0x0262ef7ee164c5c2ad4f156fe587fb2ba033662bbde8f79fb22a0263f8415162), uint256(0x1b816c36e9d1d1309135546cae3d944253e1a72040bbea26d22518bbb87ce761));
        vk.gamma_abc[448] = Pairing.G1Point(uint256(0x131c5e649b60067d921c20fb2196ff7f6120a6e50a8d37ed038c2432cebfb751), uint256(0x16b1b75fb899d0ef035e6fbcb18e0572cd3965d7fde957f3db0b6a88b1940fe6));
        vk.gamma_abc[449] = Pairing.G1Point(uint256(0x1ebf2a296c8fd2f66dcbbdf86b7eeb233a2c62bce53a3b9247da98c73ff72229), uint256(0x0140e1859d3daa709cbb52ffc7738c9f3a29ca7f30b4de3360db08989fe441ad));
        vk.gamma_abc[450] = Pairing.G1Point(uint256(0x07c044d8b61be743e26302c712fb834207c42a834febcd6faee661db4e692118), uint256(0x091e04f8e1b6ee22acf82a1b7b853412062d8fed149c04fe2303ae6996ff624c));
        vk.gamma_abc[451] = Pairing.G1Point(uint256(0x24034643e12ebbc4cfb3528ab74659a11cd7e0bc6da6d779dc216c30b69c1ae9), uint256(0x11b09f7a396e91a989d9e01b3fca67db994bd3edc9ea3e73c18a938b447e525a));
        vk.gamma_abc[452] = Pairing.G1Point(uint256(0x119f5b1fc24bce603ace156aee89fa666cbf23331c23c3e2c1bc237f1056054e), uint256(0x26e8f20ba6869c17fb46958e5f6e69242fb1c4779e1a0999031a1f8700a7d65e));
        vk.gamma_abc[453] = Pairing.G1Point(uint256(0x2cf975056002553ed592ef0930649cd80c2f889aae0940c87028c4e08e21cd37), uint256(0x216d4049cd6e7f6bbb75ba314ceb72631db585dd1b3cd32627c23ce5188e6543));
        vk.gamma_abc[454] = Pairing.G1Point(uint256(0x0801e9c7d174e6513b269879d3fb350a4d074ae6fdb3c77311ff881f2847e406), uint256(0x2253c56e5a3b0b59b6998ccf504a5fd1714eafc70c8c09d253382af240517cf0));
        vk.gamma_abc[455] = Pairing.G1Point(uint256(0x2e5659efd94717f181ea5fc4a378fb4c92a9c85e73b2b1155103fa62bfb10a0f), uint256(0x08e9470d749ad1eac645a74dc4f0f6aa53e1fd041d781dd97ac7671619128b79));
        vk.gamma_abc[456] = Pairing.G1Point(uint256(0x263027f8afc5c7ba8c43657a107830ef1e5d0429cefad7c9346f613588c7a211), uint256(0x1ad477b82347e6d29f32932043bd70e243484aacfc34943d5217ad82a2e5ab94));
        vk.gamma_abc[457] = Pairing.G1Point(uint256(0x1868dd2ca862ca3e2585ef9570bf97da4311c9f7fe6010c6708d55839ced6749), uint256(0x11da206f37ae4cda61abcd776b6af3e7f03cb98d54c9ffbd1ddd56505fa64a07));
        vk.gamma_abc[458] = Pairing.G1Point(uint256(0x19311e4f3e3880afb4cb511e2a2d6d6f7261d7fdb038d69610b86891c12b7ff3), uint256(0x07abbd5e94f7a587d2fb08b2f1344050c9e363cd0649a98f52a1ac1fb6ee0858));
        vk.gamma_abc[459] = Pairing.G1Point(uint256(0x0354a5248b3c436dac9c055c1d5896e3af82dfb7a13178c4ebbd38c6a2c97963), uint256(0x1cb5c6fa2e056cdfe17f7d188df725bc74afcc9d693691f71b4af29f23eae1d3));
        vk.gamma_abc[460] = Pairing.G1Point(uint256(0x17d09c19b7fbcc2a1b69bab5605dc007eef49370ccd707ea605741a06f5f1716), uint256(0x021d215c4617484e3e63dbdc2ac15763cd12a21bc76dd290d57130748334d970));
        vk.gamma_abc[461] = Pairing.G1Point(uint256(0x227173a50c2d20aa26d0b0ab321eec7ff238cde0dc4fa58e696be3809ad64c23), uint256(0x13b372880575f94201d522e03e7319f2d20869e1ec3492417e2251d5493339b9));
        vk.gamma_abc[462] = Pairing.G1Point(uint256(0x14cd12ea4d70d2e613c527f4001e23bb215e2fb047c58c03d8b67b6a6c5f2256), uint256(0x19fe5543e54493e80c3cf8f3c837112d507fa46d401c4c9b6b9a85961392176c));
        vk.gamma_abc[463] = Pairing.G1Point(uint256(0x0b178922aacac85cdf4deabcf08b4ee8c45ca0d7d30eaf3ad0a0342ff5eab912), uint256(0x11898d297836a3d6440696760f6b0d06658d0101d8b18469f2b37acba472eb8c));
        vk.gamma_abc[464] = Pairing.G1Point(uint256(0x10c26f9bf508f7ba141cf06ce19821430edaf852acd2e819acad77873912a4bd), uint256(0x26afafe535a45b8ebac8c143efd9773f197d35f7b6eb3463c1c06174e493f10f));
        vk.gamma_abc[465] = Pairing.G1Point(uint256(0x1c89167230e1b9c539fbc1b5a7c25d47088d6f03438dce0ed9a0ecf05a245f5b), uint256(0x268a1c8b23a8cdab539ece14241c5667c3e7ae53a74ec7e9c794fbbc7e66a64a));
        vk.gamma_abc[466] = Pairing.G1Point(uint256(0x052428f99e1398506568b26819394834f4ddcb24b33984f6a39a20f8e429f203), uint256(0x063dbf652e8c78a776ce138ce8bad48678e374f47cf4b79ea253ebd3aca0b34b));
        vk.gamma_abc[467] = Pairing.G1Point(uint256(0x21b745b2e80bd404f4d86aa4e9229858f69f7173d4adeef0b2cba058e6961c6b), uint256(0x0009dfcf68b59690c34009f7b5333a11ad823db78362fe108a99717286dc888c));
        vk.gamma_abc[468] = Pairing.G1Point(uint256(0x2eb80b269f149ed612c083f65471147e5b507b1e88849bad11acc839df8f0df8), uint256(0x1bdd8efc5d047e22dffad84b328c906ed1eff7a5a5c22bb7cb51a2c332b9dca3));
        vk.gamma_abc[469] = Pairing.G1Point(uint256(0x10778481146d09d031f219439426975ef52aa6cff2e7c2c32acd077243a42e0b), uint256(0x1f894b7c344655ca87f88a6d9fe6cf45382e876b88205d575176ddd970d939aa));
        vk.gamma_abc[470] = Pairing.G1Point(uint256(0x1efad43d6de57f5c481e8750dc209171de3796c222ce60b6ec2aaa170c5ebe00), uint256(0x000ddbc0c4f8d47489f4605e1816ee354a9184290dcc506ce759ccbaae6a53be));
        vk.gamma_abc[471] = Pairing.G1Point(uint256(0x01a08bf0aa52b88fd8e9fab3885b744d3368753e09e01a1ad582dc60c9e40242), uint256(0x077e1f32e7cd89683a2f4fcb5c723a038211d558e7b9c556ee81f5a8315e8aa5));
        vk.gamma_abc[472] = Pairing.G1Point(uint256(0x0e4e4e8a7c580bf91ba4f2b7c837e21bd3fabe2b551d0417eb2c3c15383d962d), uint256(0x20b135861a8e9f0f92a5875048ccb94bad62db91a122ab557cf9ba30c6b0fb97));
        vk.gamma_abc[473] = Pairing.G1Point(uint256(0x0c6d53607d1996765df0b519a34157cb2898a989a5c9dfed4d9aee355a0f699c), uint256(0x1fe4708f6032b2266ace79fc3ee55a38753f476dcf701cf7a49388c734f7e813));
        vk.gamma_abc[474] = Pairing.G1Point(uint256(0x0788d1825f0950fdb4fc8328769a9dc5082aed5a8f5345c3645a77e7e5ad746e), uint256(0x0b87d7fad4ffa3c3dcd05f01c300b256be7126528f5dc9117128d97be5d2e87f));
        vk.gamma_abc[475] = Pairing.G1Point(uint256(0x199bfeaaa1cfb41a59ba5e5448622d5a349241f8d0e5436e3ac19122cdbd9019), uint256(0x2395623afa0ab4f25f6e0be3fda36783cd69139fe6a0a502dfd40d25c297bb3d));
        vk.gamma_abc[476] = Pairing.G1Point(uint256(0x150ed7591bcb5173cd3dde5fa8fdd91b1cbd7453848d36de10daa979f4f25334), uint256(0x182e4e71dc495a9c1700993e1de9c1afe7c2b9b49f48c21cabb5c98e4710a482));
        vk.gamma_abc[477] = Pairing.G1Point(uint256(0x232d185528923e5380d1470775afc0a0307ad84393763d881fbba082792245c8), uint256(0x0b3b01a225bcc26f5d6890692283b0f6e1f986c5e987de59ff497c355a3745ba));
        vk.gamma_abc[478] = Pairing.G1Point(uint256(0x0e3dc42e45896194266052930d77b16b99d9fd876e08121f47c10a4ca606cd1c), uint256(0x276fe8941c17441e2bc7c85f6aa74fda87669d4d7fbb3a83c0c5abcffadb1814));
        vk.gamma_abc[479] = Pairing.G1Point(uint256(0x0639174410c3140b2ca33e6c046f3741ebe8ac8c84f9865cad113f2a1fc530c2), uint256(0x17b20635e130a0a30c74978f00e899451ae0466c6f9ecdece885e697171164a3));
        vk.gamma_abc[480] = Pairing.G1Point(uint256(0x00e024857c65e4e1f1d4b22c5d82cf0f779ef5c0c598d27fb910593651967e71), uint256(0x1b6cd53e2a355b1c19afebeb8c15843285cf99e1bda8cea41069c8a8b92caa25));
        vk.gamma_abc[481] = Pairing.G1Point(uint256(0x087736e1422f4e39999806a717b0fbb7df5047f54de36f9971d123c783f94cee), uint256(0x2ce99852bec725208b3eb2240cc9a4b02e1bec7da2090e7e0a48b1444e6f1eb2));
        vk.gamma_abc[482] = Pairing.G1Point(uint256(0x2b95c2fa916776f8e1f22225286690b468dbbdface6e284b98297919b7516923), uint256(0x2ae20c2d65f2defd43c398dc18b8a0bb3c13159fd65da6a91143e704dc505bde));
        vk.gamma_abc[483] = Pairing.G1Point(uint256(0x1f9413543958c97f604c978cdf27a78af82382258cebd537da3fd6ed22005d96), uint256(0x27bbaef1f5bfd0593d751906991565b1aab26b03892f7229c7780f476e1aef15));
        vk.gamma_abc[484] = Pairing.G1Point(uint256(0x17705a6d925a58aafe83c7741a1bf97841666907e9582da23a896d1ded411b31), uint256(0x02326423a5776141204eeb37a2f220089b30600cefdfa5aeaff20310d1f1745e));
        vk.gamma_abc[485] = Pairing.G1Point(uint256(0x2df45d03e3fe32fcc75f28300c011950368521972696360adf4daa35f0e8138c), uint256(0x0945774d52ba212c2045b402a12e6fd43dc00b583e2f8912fe1e579a4945f498));
        vk.gamma_abc[486] = Pairing.G1Point(uint256(0x08a07f6760ffc8320126f578d07e52795b1a8bcfd6467911d845658f1b305fe0), uint256(0x159639f6763d26521ebc89c35b424ac88c9800684c68b20116a2d3c75517dfd9));
        vk.gamma_abc[487] = Pairing.G1Point(uint256(0x290865650cd352fe7d5ff8874f60a715a531fbfa2a809bc610cd31a1dfcedb00), uint256(0x0b6911d3548052c60c95ab6c0a56572fae4f0febf4a18aceb09778645adc7447));
        vk.gamma_abc[488] = Pairing.G1Point(uint256(0x2316781514d5a54d8a4b05b0ba8f411c6943798c060f54f6deeedc96c0260285), uint256(0x0dfe80003d29f8a7622ebff5f328a2660aeffd05f513892a697897fc76751bce));
        vk.gamma_abc[489] = Pairing.G1Point(uint256(0x0debd1252e5765405dd1b7da9d8d9d9aa254dd9d21b4f253d98d825e0a2c8932), uint256(0x2930fbc4fb6c130bfa591d58e23babb8bce38fa706caaa4d79da58365a6fedfa));
        vk.gamma_abc[490] = Pairing.G1Point(uint256(0x224403243006606468e56fd2af2b45794fe7aca6c09326d5e6bad8464b76cc25), uint256(0x2d3a0ef99694b0632c8a962b572a6bef6025123489144c28e0bc03fca20eac97));
        vk.gamma_abc[491] = Pairing.G1Point(uint256(0x06d22d3e36ffdc14d3b72c5197c1d41c1188b0e9ce7a0bf71c2ae52f6915ac4d), uint256(0x20474340a665ed0d9d9efcad5163d57951507cd09f7b2f4df5e874035efe613d));
        vk.gamma_abc[492] = Pairing.G1Point(uint256(0x0bf4c097c9f43156c346f33ba8bd496a16b05c1e57aa49d5a7ce942d5a5244fe), uint256(0x1737f7c93744cba146a7641a555c3ce7018aa8523e89791ced7784c3dd4b4271));
        vk.gamma_abc[493] = Pairing.G1Point(uint256(0x2e80c3190a1236cfffe67504d10479a411c97da7081a8aa4cc85dbd3a037e540), uint256(0x0d2342ea7391e944795d6cbca4c08d53fcc189eefdb8e892baa5ad87a5351aef));
        vk.gamma_abc[494] = Pairing.G1Point(uint256(0x19cb6abdf51688e3bdcc9f6707a150e3b89ad0db930d7590b0294af5159c2bc6), uint256(0x183c45675ef1b70d1141133c7a56a2a3c1dddd4a4ff72c857070758017771633));
        vk.gamma_abc[495] = Pairing.G1Point(uint256(0x05f92bbd5a5f19bdb60804e80c4e5d763341fa9b5d320cd6e9591ff26ae69d48), uint256(0x18b7ae062c1579952bd3f5962c5a3985eaac3bdb55c39917c489718cedae4857));
        vk.gamma_abc[496] = Pairing.G1Point(uint256(0x2683bdf1b1385dda0b1ec733d71c09d52a76b355b1184f62959f37bc4699d9d8), uint256(0x0c2de024ec632b1273266e32fe8e02a080a9ac57875153c39365024319f7a050));
        vk.gamma_abc[497] = Pairing.G1Point(uint256(0x20eed5045e6cc369a75fe60534784b3f4ce7a45bcd3fdc656101ebf0a4990e90), uint256(0x12091e57fa259d49573b4679653efb543b92cafa8995e88ebc7a1634a218a2bf));
        vk.gamma_abc[498] = Pairing.G1Point(uint256(0x1173081795f090df7359020ac4f3fe74d3cddafa45eb0fb3107f828fd3dcba61), uint256(0x19f45dea2bf40889521bc9156ae6734adf3cd2ed3db7c31e40cb71755b5721ef));
        vk.gamma_abc[499] = Pairing.G1Point(uint256(0x1e003effa78ab6675b596e63670cd57d70b4ebc28633323d7b3d5860ee8f46e3), uint256(0x1825ea06da3eeecca4fd5ec4e7bf9d2412392b00ef187c1ff3685a61b9b36f29));
        vk.gamma_abc[500] = Pairing.G1Point(uint256(0x2904eb510d5908fa2c740aa507f415de5784850aaad98f5524e05fbeb6e468af), uint256(0x1208b6df27c48ae2156ca42c23c90f58ce89f407faa61e98a6d81c2d8fcbc8f5));
        vk.gamma_abc[501] = Pairing.G1Point(uint256(0x14052558a782a98b73bee48085af9776e0974b7d8208fca29d523afcaef039b1), uint256(0x0ab7293f1a0639873f01dd434e69269f133b9eb8ce971fc5cee10f9d6c0465bb));
        vk.gamma_abc[502] = Pairing.G1Point(uint256(0x2af3da5632f38e95e02dd96f972c5cc0e2d73ba30070d6e5f27b501e46c5233c), uint256(0x06adfed80d92f8a88802fd0fdedc3e1b06b73cdd6e94d656eefeb815bb9359b9));
        vk.gamma_abc[503] = Pairing.G1Point(uint256(0x18e7cf08e3a47e90c588862f8a3bea54038a2c4c20579139de4c27be9bdaca96), uint256(0x1fd1d6e0a364a59b86a756631b160f073a7b3763bfeb52c67b439db17fda3770));
        vk.gamma_abc[504] = Pairing.G1Point(uint256(0x078fd458ebd9773c4fe7ef6cf0403eab0b28cf505ee6162dd1e7924345a63350), uint256(0x10987920a71f49406e03b46f55e5835563df6723826b9b7997d8664ea461c920));
        vk.gamma_abc[505] = Pairing.G1Point(uint256(0x292f45c6b7347b46a93d86826199d536b3df6e454e2646535cf166cd3c52e16e), uint256(0x0b122b5c94dfa3f9377ded17ecb4860ef014f48a7b9bcddee7e60b648f8c3d31));
        vk.gamma_abc[506] = Pairing.G1Point(uint256(0x23386a45c96d3b554db1cce5e54fb485d447e4ee856d8f51e48233b1408c94a2), uint256(0x1b4f1b9c81fb8c75040c779e0b1bab1ac18f9a54f5fea5f615aa9582bcb68693));
        vk.gamma_abc[507] = Pairing.G1Point(uint256(0x19df9c8729bbb6bf267e5adbc027d43b52bb9ca4b2fc629fd7c3e8125a961681), uint256(0x1c014725fe9ccb9dc4e103fd7744dee1304965ce2e2085ed84e4f9d7a776264d));
        vk.gamma_abc[508] = Pairing.G1Point(uint256(0x13fb3892ecc025142bc80277adb2c2e1e80d98039ac1b0cbca91438055627e6d), uint256(0x1b7a49d279a481984a177d4e5837ae314240cb16a07595ec16b6715bc10da4f2));
        vk.gamma_abc[509] = Pairing.G1Point(uint256(0x1c92b5fb80d9bddac7e94f2b20d1a5f399a11a62209eeec03de736e1cfb5a870), uint256(0x136d01c36465317ccac252ba662fb0f031147036b537cda5fd6372f89a4fb690));
        vk.gamma_abc[510] = Pairing.G1Point(uint256(0x0f59af9393a8c0c42c840e771f3fe281a9a1e0bffbd88fdc3770fc860b47e2f9), uint256(0x234737ae08b46b18544ab765de6fafd13e9a15b72ade1f162e3c7108d8156d30));
        vk.gamma_abc[511] = Pairing.G1Point(uint256(0x09cd0ffa0448801bf7f94dd494e1214b2b3e214996843e2000b881d5dcb4f92a), uint256(0x0b0024a06daf31da17a4a9dc0f67f369ddc8d513eb4596b14f49f3c638810a77));
        vk.gamma_abc[512] = Pairing.G1Point(uint256(0x03c034e7ee930576b7858bdbcf01d30cad59ac27095143394363a1afd568452d), uint256(0x0920612cb455b8d1c918ab95f2541fe5f81207d4cc66fbb40bbaf23193bf6fc2));
        vk.gamma_abc[513] = Pairing.G1Point(uint256(0x11f0b6951129356b01d2c392154bae95035bac78efb49b40d8f9891dcad34050), uint256(0x21d32ce914c3e69179a805a187912027903d578d4724bb14bc8f6ea8a14137de));
        vk.gamma_abc[514] = Pairing.G1Point(uint256(0x1227b57194aa480ab5c1773fea216952f7475d404e842bcf1295548f908cc8f0), uint256(0x2606b4449ac6faed3acebacd1b2bd58915cab3ad5ff6a826a524911fc92ff66b));
    }
    function verify(uint[] memory input, Proof memory proof) internal returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.gamma_abc.length);
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field);
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.gamma_abc[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.gamma_abc[0]);
        if(!Pairing.pairingProd4(
             proof.a, proof.b,
             Pairing.negate(vk_x), vk.gamma,
             Pairing.negate(proof.c), vk.delta,
             Pairing.negate(vk.a), vk.b)) return 1;
        return 0;
    }
    event Verified(string s);
    function verifyTx(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[514] memory input
        ) public returns (bool r) {
        Proof memory proof;
        proof.a = Pairing.G1Point(a[0], a[1]);
        proof.b = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.c = Pairing.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            emit Verified("Transaction successfully verified.");
            return true;
        } else {
            return false;
        }
    }
}
