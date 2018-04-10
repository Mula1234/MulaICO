pragma solidity ^0.4.17;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */

library SafeMath {

    uint256 constant SIGNIF_BITS = 236;
    uint256 constant EXP_BITS = 19;
    uint256 constant SIGN_BITS = 1;
    
    uint256 constant EXP_MIN = 0;
    uint256 constant EXP_BIAS = 262143;
    uint256 constant EXP_MAX = 524287;
    
    uint256 constant INT128_MAX = (uint256(1) << 127) - 1;
    uint256 constant INT128_MIN = (uint256(1) << 127);
    
    uint256 constant SIGNIF_MAX = (uint256(2) << SIGNIF_BITS) - 1;
    uint256 constant SIGNIF_MIN = (uint256(1) << SIGNIF_BITS);
    bytes32 constant SIGNIF_MAX_BYTES = bytes32(SIGNIF_MAX);
    bytes32 constant SIGNIF_MIN_BYTES = bytes32(SIGNIF_MIN);

    bytes32 constant ZERO_BYTES = bytes32(0);

    uint256 constant INV_SQRT_MAGIC = uint256(bytes32(0x5fffe6eb50c7b537a9cd9f02e504fcfbfd9ec519e04e8f0a29d961d2aaeb2223));
    
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {

    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;

  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {

    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;

  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {

    assert(b <= a);
    return a - b;

  }
  
  function add(uint256 a, uint256 b) internal constant returns (uint256) {

    uint256 c = a + b;
    assert(c >= a);
    return c;

  }

    function toArray(bytes32 a) public constant returns (uint256[3] memory result) {
        if (a == ZERO_BYTES) {
            return result;
        }
        uint256 newSign = uint256(a >> 255);
        uint256 newExp = uint256((a << SIGN_BITS) >> (SIGNIF_BITS+SIGN_BITS));
       
        uint256 newSignif = uint256((a << (EXP_BITS + SIGN_BITS)) >> (EXP_BITS + SIGN_BITS)) + SIGNIF_MIN;
        return [newSign, newExp, newSignif];
    }
    
    function fromArray(uint256[3] _array) public constant returns (bytes32 packed) {
        if (_array[0] == 0 && _array[1] == 0 && _array[2] == 0) {
            return ZERO_BYTES;
        }
        bytes32 packedSign = bytes32(_array[0] << 255);
        bytes32 packedExp = bytes32(_array[1] << SIGNIF_BITS);
        bytes32 packedSignif = bytes32(_array[2]) ^ SIGNIF_MIN_BYTES;    
        packed = packedSign | packedExp | packedSignif;
    }
    
    function addFloat(bytes32 a, bytes32 b) public constant returns (bytes32 result) {
        uint256[3] memory aArray = toArray(a);
        uint256[3] memory bArray = toArray(b);
        return fromArray(addArrays(aArray, bArray));
    }
    
    function addArrays(uint256[3] aArray, uint256[3] bArray) internal constant returns (uint256[3] memory result) {
        if (aArray[0] == 0 && aArray[1] == 0 && aArray[2] == 0) {
            return bArray;
        }
        if (bArray[0] == 0 && bArray[1] == 0 && bArray[2] == 0) {
            return aArray;
        }
        uint256 newExp = aArray[1];
        uint256 expA = aArray[1];
        uint256 expB = bArray[1];
        uint256 signifA = aArray[2];
        uint256 signifB = bArray[2];
        uint256 signA = aArray[0];
        uint256 signB = bArray[0];
        uint256 newSignif = 0;
        uint256 newSign = 0;

        if (expB > expA) {
            newExp = expB;
            signifA = signifA >> (expB - expA);
        } else if (expA > expB) {
            signifB = signifB >> (expA - expB);
        }
        
        if (signA + signB == 2) {
            newSign = 1;
            newSignif = signifA + signifB;
        } else if (signA == 1) {
            if (signifA > signifB) {
                newSignif = signifA - signifB;
                newSign = 1;
            } else if (signifB >= signifA) {
                newSignif = signifB - signifA;
                newSign = 0;
            }
        } else if (signB == 1) {
            if (signifB > signifA) {
                newSignif = signifB - signifA;
                newSign = 1;
            } else if (signifA >= signifB) {
                newSignif = signifA - signifB;
                newSign = 0;
            }
        } else {
            newSignif = signifA + signifB;
            newSign = 0;
        }
        if (newSignif == 0) {
            return [uint256(0), uint256(0), uint256(0)];
        }
        while (newSignif > SIGNIF_MAX) {
            newSignif = newSignif >> 1;
            newExp++;
        }
        while (newSignif < SIGNIF_MIN) {
            newSignif = newSignif << 1;
            newExp--;
        }        
        return [newSign, newExp, newSignif];
    }
   

    function negate(bytes32 a) public constant returns (bytes32 result) {
        if (a == ZERO_BYTES) {
            return a;
        }
        return a ^ bytes32(uint256(1) << 255);
    } 

    function negateArray(uint256[3] aArray) internal constant returns (uint256[3] memory result) {
        if (aArray[0] == 0 && aArray[1] == 0 && aArray[2] == 0) {
            return aArray;
        }
        return [(aArray[0] + 1 )%2, aArray[1], aArray[2]];
    }
 
    function subFloat(bytes32 a, bytes32 b) public constant returns (bytes32 result) {
        uint256[3] memory aArray = toArray(a);
        uint256[3] memory bArray = toArray(negate(b));
        return fromArray(addArrays(aArray, bArray));
    }
    
    function subArrays(uint256[3] aArray, uint256[3] _bArray) internal constant returns (uint256[3] memory result) {
        if (aArray[0] == 0 && aArray[1] == 0 && aArray[2] == 0) {
            return negateArray(_bArray);
        }
        if (_bArray[0] == 0 && _bArray[1] == 0 && _bArray[2] == 0) {
            return aArray;
        }
        uint256[3] memory bArray = negateArray(_bArray);
        return addArrays(aArray, bArray);
    }
  
    function mulFloat(bytes32 a, bytes32 b) public constant returns (bytes32 result) {
        uint256[3] memory aArray = toArray(a);
        uint256[3] memory bArray = toArray(b);
        return fromArray(mulArrays(aArray, bArray));
    }
    
    function mulArrays(uint256[3] aArray, uint256[3] bArray) internal constant returns (uint256[3] memory result) {
        if (aArray[0] == 0 && aArray[1] == 0 && aArray[2] == 0) {
            return [uint256(0), uint256(0), uint256(0)];
        }
        if (bArray[0] == 0 && bArray[1] == 0 && bArray[2] == 0) {
            return [uint256(0), uint256(0), uint256(0)];
        }
        uint256 newSign = (aArray[0] + bArray[0]) % 2;
        uint256 newExp = (aArray[1] + bArray[1]) - EXP_BIAS;
        if (newExp > EXP_MAX) {
            revert();
            newExp = EXP_MAX;
            newSignif = SIGNIF_MAX;
            return [newSign, newExp, newSignif];
        }

        uint256 topA = aArray[2] >> (SIGNIF_BITS >> 1);
        uint256 botA = aArray[2] << (255 - (SIGNIF_BITS >> 1)) >> 256;

        uint256 topB = bArray[2] >> (SIGNIF_BITS >> 1);
        uint256 botB = bArray[2] << (255 - (SIGNIF_BITS >> 1)) >> 256;

        uint256 bottomMul = botA*botB;
        uint256 midMul = topA*botB + botA*topB;
        uint256 newSignif = topA*topB;

        midMul = midMul + (bottomMul >> (SIGNIF_BITS >> 1));
        newSignif = newSignif + (midMul >> (SIGNIF_BITS >> 1));

        while (newSignif > SIGNIF_MAX) {
            newSignif = newSignif >> 1;
            newExp++;
        }
        return [newSign, newExp, newSignif];
    }   
    
    function fastInvSqrt(bytes32 a) public constant returns (bytes32 result) {
        require(compare(a, ZERO_BYTES) == 1);
        uint256 tmp = INV_SQRT_MAGIC - (uint256(a) >> 1);
        uint256[3] memory THREEHALFS = toArray(0x3FFFF80000000000000000000000000000000000000000000000000000000000);
        uint256[3] memory resArray = toArray(bytes32(tmp));
        uint256[3] memory resDivByTwo = toArray(a);
        resDivByTwo[1] = resDivByTwo[1]-1;
        resArray = mulArrays(resArray, subArrays(THREEHALFS, mulArrays(resDivByTwo, mulArrays(resArray, resArray) ) ) ); 
        // resArray = mulArrays(resArray, subArrays(THREEHALFS, mulArrays(resDivByTwo, mulArrays(resArray, resArray) ) ) );
        return fromArray(resArray);
        // y = y * (threehalfs - (x2 * y * y));

    }

    function divFloat(bytes32 a, bytes32 b) public constant returns (bytes32 result) {
        if (b == ZERO_BYTES) {
            revert();
        }
        if (compare(ZERO_BYTES, b) == 1) {
            bytes32 _b = negate(b);
            _b = mulFloat(a, mulFloat(fastInvSqrt(_b),fastInvSqrt(_b)));
            return negate(_b);
        }
        return mulFloat(fastInvSqrt(b), mulFloat(a,fastInvSqrt(b)));
    }
    
    function divArrays(uint256[3] aArray, uint256[3] bArray) internal constant returns (uint256[3] memory result) {
        if (aArray[0] == 0 && aArray[1] == 0 && aArray[2] == 0) {
            return [uint256(0), uint256(0), uint256(0)];
        }
        if (bArray[0] == 0 && bArray[1] == 0 && bArray[2] == 0) {
            revert();
        }
        bytes32 a = fromArray(aArray);
        bytes32 b = fromArray(bArray);
        return toArray(divFloat(a,b));
    }    

    
    function divNaive(bytes32 a, bytes32 b) public constant returns (bytes32 result) {
        uint256[3] memory aArray = toArray(a);
        uint256[3] memory bArray = toArray(b);
        return fromArray(divNaiveArrays(aArray, bArray));
    }
    
    function divNaiveArrays(uint256[3] aArray, uint256[3] bArray) internal constant returns (uint256[3] memory result) {
        if (aArray[0] == 0 && aArray[1] == 0 && aArray[2] == 0) {
            return [uint256(0), uint256(0), uint256(0)];
        }
        if (bArray[0] == 0 && bArray[1] == 0 && bArray[2] == 0) {
            revert();
        }
        uint256 expA = aArray[1];
        uint256 expB = bArray[1];
        uint256 signifA = aArray[2];
        uint256 signifB = bArray[2];
        uint256 signA = aArray[0];
        uint256 signB = bArray[0];
        uint256 newExp = EXP_BIAS + expA - expB;
        assert(newExp > EXP_MIN && newExp < EXP_MAX);
        uint256 newSign = (signA + signB) % 2;
        uint256 newSignif = 0;
        uint256 cop = signifA;
        if (signifA < signifB) {
            cop = cop << 1;
            newExp--;
        }
        uint256 shift = SIGNIF_BITS;
        for (uint256 i = 0; i < SIGNIF_BITS; i++) {
            newSignif += (cop/signifB) << shift;
            shift--;
            cop = (cop % signifB) << 1;
        }
        return [newSign, newExp, newSignif];
    }    

    function compare(bytes32 a, bytes32 b) public constant returns (int8 result) {
        uint256[3] memory aArray = toArray(a);
        uint256[3] memory bArray = toArray(b);
        return compareArrays(aArray, bArray);
    }
    
    function compareArrays(uint256[3] aArray, uint256[3] bArray) internal constant returns (int8 result) {
        if (aArray[0]==0 && bArray[0] == 0) {
            return compareAbsArrays(aArray, bArray);
        } else if (aArray[0]==1 && bArray[0] == 1) {
            return -compareAbsArrays(aArray, bArray);
        } else if (aArray[0] > bArray[0]) {
            return -1;
        }
        return 1;
    }

    function compareAbs(bytes32 a, bytes32 b) public constant returns (int8 result) {
        uint256[3] memory aArray = toArray(a);
        uint256[3] memory bArray = toArray(b);
        return compareAbsArrays(aArray, bArray);
    }

    function compareAbsArrays(uint256[3] aArray, uint256[3] bArray) internal constant returns (int8 result) {
        if (aArray[1] > bArray[1]) {
            return 1;
        } else if (aArray[1] < bArray[1]) {
            return -1;
        } else {
            if (aArray[2] > bArray[2]) {
                return 1;
            } else if (aArray[2] < bArray[2]) {
                return -1;
            }
        }
        return 0;
    }

    function log2bytes(bytes32 a) public constant returns (bytes32 result) {
        uint256[3] memory aArray = toArray(a);
        return fromArray(log2Array(aArray));
    }
    
    function log2Array(uint256[3] aArray) internal constant returns (uint256[3] memory result) {
        require(aArray[0] == 0);
        result = initFromIntToArray(int256(aArray[1]) - int256(EXP_BIAS));
        uint256[3] memory ONE = initFromIntToArray(1);
        uint256[3] memory TWO = initFromIntToArray(2);
        uint256[3] memory tmp = initFromIntToArray(int256(aArray[2]));
        uint256[3] memory ZERO = [uint256(0), uint256(0), uint256(0)];
        tmp[1] = tmp[1] - SIGNIF_BITS;
        uint256 numIterations = 16;
        for (uint256 i = 1; i <= numIterations; i++) {
            tmp = mulArrays(tmp, tmp);
            ZERO = mulArrays(ZERO, TWO);
            if (i==0) {
                return tmp;
            }
            if (compareArrays(tmp, TWO) == 1) {
                ZERO = addArrays(ZERO, ONE);
                tmp[1] = tmp[1] - 1;
            }
        }
        ZERO[1] = ZERO[1] - numIterations;
        // ZERO[1] = divArrays(ZERO, initFromIntToArray(int256(uint256(1) << numIterations)));
        result = addArrays(result, ZERO);
        return result;
    }

    function initFromInt(int256 a) public constant returns (bytes32 result) {
        if (a == 0) {
            return ZERO_BYTES;
        }
        uint256[3] memory tmp = initFromIntToArray(a);
        return fromArray(tmp);
    }
    
    function initFromIntToArray(int256 a) internal constant returns (uint256[3] memory result) {
        if (a==0) {
            return result;
        }
        int256 abs = a;
        uint256 newSign = 0;
        if (abs < 0) {
            newSign = 1;
            abs = -abs; 
        }
        uint256 newExp = EXP_BIAS + SIGNIF_BITS;
        uint256 newSignif = uint256(abs);
        while (newSignif > SIGNIF_MAX) {
            newSignif = newSignif >> 1;
            newExp++;
        }
        while (newSignif < SIGNIF_MIN) {
            newSignif = newSignif << 1;
            newExp--;
        }
        assert(newSignif >= SIGNIF_MIN && newSignif <= SIGNIF_MAX);
        assert(newExp < EXP_MAX && newExp > EXP_MIN);
        return [newSign, newExp, newSignif];
    }

    function toBytes(uint256 x) constant returns (bytes b) {
      b = new bytes(32);
      assembly { mstore(add(b, 32), x) }
    }

    function toUint(bytes32 _number) constant returns (uint) {

        return uint(_number);

    }

}