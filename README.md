# mcdonalds-monopoly

## Mumbai testnet smart contracts
- GamePieces: [0x116678ed63e93d814c4ba45adb56d899eb996fd2](https://mumbai.polygonscan.com/address/0x116678ed63e93d814c4ba45adb56d899eb996fd2)
- Prizes: [0x45b498e9af757736f51c662b3fee0d6687670106](https://mumbai.polygonscan.com/address/0x45b498e9af757736f51c662b3fee0d6687670106)

### How to interact through PolygonScan
1. Obtain Mumbai MATIC. [FAUCET](https://faucet.polygon.technology/).
2. Mint GamePiece using #5 requestRandomWords. Input your wallet. [WRITE CONTRACT](https://mumbai.polygonscan.com/address/0x116678ed63e93d814c4ba45adb56d899eb996fd2#writeContract).
- OPTIONAL: Click "View Transaction" to obtain your requestId from the event log. Copy this value.
- OPTIONAL: Check Game Piece using #13 s_requests. Input your requestId. [READ CONTRACT](https://mumbai.polygonscan.com/address/0x116678ed63e93d814c4ba45adb56d899eb996fd2#readContract).
- OPTIONAL: Check revealed property by looking at "randomWord" value. 1 = MED_AVE. 2 = BAL_AVE. 3 = CONN_AVE. 4 = VER_AVE. 5 = ORI_AVE.
- OPTIONAL: Verify correct revealed property using #3 accountToPropertyCount. Input your wallet and property name. [READ CONTRACT](https://mumbai.polygonscan.com/address/0x116678ed63e93d814c4ba45adb56d899eb996fd2#readContract).
3. Repeat step 2 until you obtain a property set (Brown Set = MED_AVE & BAL_AVE, Light Blue Set = CONN_AVE & VER_AVE & ORI_AVE).
4. Claim Prize using #2 claimBrownSet or #3 claimLightBlueSet. Input your wallet. [WRITE CONTRACT](https://mumbai.polygonscan.com/address/0x116678ed63e93d814c4ba45adb56d899eb996fd2#writeContract).