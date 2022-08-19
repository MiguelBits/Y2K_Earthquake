// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";
import {VaultFactory} from "../src/VaultFactory.sol";
import {Controller} from "../src/Controller.sol";
import {PegOracle} from "../src/oracles/PegOracle.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";
import "@chainlink/interfaces/AggregatorV3Interface.sol";

import {FakeOracle} from "./oracles/FakeOracle.sol";
import {IWETH} from "./interfaces/IWETH.sol";

contract AssertTest is Test {

    VaultFactory vaultFactory;
    Controller controller;

    address WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    address tokenFRAX = 0x17FC002b466eEc40DaE837Fc4bE5c67993ddBd6F;
    address tokenMIM = 0xFEa7a6a0B346362BF88A9e4A88416B77a57D6c2A;
    address tokenFEI = 0x4A717522566C7A09FD2774cceDC5A8c43C5F9FD2;
    address tokenUSDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address tokenDAI = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;
    address tokenSTETH = 0xEfa0dB536d2c8089685630fafe88CF7805966FC3;

    address oracleFRAX = 0x0809E3d38d1B4214958faf06D8b1B1a2b73f2ab8;
    address oracleMIM = 0x87121F6c9A9F6E90E59591E4Cf4804873f54A95b;
    address oracleFEI = 0x7c4720086E6feb755dab542c46DE4f728E88304d;
    address oracleUSDC = 0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3;
    address oracleDAI = 0xc5C8E77B397E531B8EC06BFb0048328B30E9eCfB;
    address oracleSTETH = 0x07C5b924399cc23c24a95c8743DE4006a32b7f2a;
    address oracleETH = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;

    address admin = address(1);

    address alice = address(2);
    address bob = address(3);
    address chad = address(4);
    address degen = address(5);

    int256 depegAAA = 99;
    int256 depegBBB = 97;
    int256 depegCCC = 95;

    uint256 endEpoch;
    uint256 beginEpoch;
    
    function setUp() public {
        vaultFactory = new VaultFactory(admin,WETH,admin);
        controller = new Controller(address(vaultFactory),admin);

        vm.prank(admin);
        vaultFactory.setController(address(controller));

        endEpoch = block.timestamp + 30 days;
        beginEpoch = block.timestamp + 2 days;
    }

    /*///////////////////////////////////////////////////////////////
                           CREATION functions
    //////////////////////////////////////////////////////////////*/

    function testPegOracleMarketCreation() public {
        PegOracle pegOracle = new PegOracle(oracleSTETH, oracleETH);
        PegOracle pegOracle2 = new PegOracle(oracleFRAX, oracleFEI);

        // //Eth price feed minus something to trigger depeg
        FakeOracle fakeOracle = new FakeOracle(oracleETH, 129919825000);
        PegOracle pegOracle3 = new PegOracle(address(fakeOracle), oracleETH);

        vm.startPrank(admin);
        vaultFactory.createNewMarket(50, tokenSTETH, depegAAA, beginEpoch, endEpoch, address(pegOracle), "y2kSTETH_99*SET");
        vaultFactory.createNewMarket(50, tokenFEI, depegBBB, beginEpoch, endEpoch, address(pegOracle2), "y2kSTETH_97*SET");
        vaultFactory.createNewMarket(50, WETH, depegCCC, beginEpoch, endEpoch, address(pegOracle3), "y2kSTETH_95*SET");
        vm.stopPrank();

        Deposit(1);
        Deposit(2);
        Deposit(3);

        int256 oracle1price1 = pegOracle.getOracle1_Price();
        int256 oracle1price2 = pegOracle.getOracle2_Price();
        emit log_named_int("oracle1price1", oracle1price1);
        emit log_named_int("oracle1price2", oracle1price2);
        (
            ,
            int256 price,
            ,
            ,
            
        ) = pegOracle.latestRoundData();
        emit log_named_int("oracle1price1 / oracle1price2", price);

        int256 oracle2price1 = pegOracle2.getOracle1_Price();
        int256 oracle2price2 = pegOracle2.getOracle2_Price();
        emit log_named_int("oracle2price1", oracle2price1);
        emit log_named_int("oracle2price2", oracle2price2);
        (
            ,
            price,
            ,
            ,
            
        ) = pegOracle2.latestRoundData();
        emit log_named_int("oracle2price1 / oracle2price2", price);

        int256 oracle3price1 = pegOracle3.getOracle1_Price();
        int256 oracle3price2 = pegOracle3.getOracle2_Price();
        emit log_named_int("oracle3price1", oracle3price1);
        emit log_named_int("oracle3price2", oracle3price2);
        (
            ,
            price,
            ,
            ,
            
        ) = pegOracle3.latestRoundData();
        emit log_named_int("oracle3price1 / oracle3price2", price);

        ControllerEndEpoch(tokenSTETH,1);
        ControllerEndEpoch(tokenFEI,2);
        ControllerEndEpoch(WETH,3);

        Withdraw();
    }

    function testALLMarketsCreation() public {
        vm.startPrank(admin);

        // Create FRAX market
        //index 1
        vaultFactory.createNewMarket(50, tokenFRAX, depegAAA, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_99*SET");
        assertTrue(Vault(vaultFactory.getVaults(1)[0]).strikePrice() == 99 * 10e16, "Decimals incorrect");
        //index 2
        vaultFactory.createNewMarket(50, tokenFRAX, depegBBB, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_97*SET");
        //index 3
        vaultFactory.createNewMarket(50, tokenFRAX, depegCCC, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_95*SET");

        // Create MIM market
        //index 4
        vaultFactory.createNewMarket(50, tokenMIM, depegAAA, beginEpoch, endEpoch, oracleMIM, "y2kMIM_99*SET");
        //index 5
        vaultFactory.createNewMarket(50, tokenMIM, depegBBB, beginEpoch, endEpoch, oracleMIM, "y2kMIM_97*SET");
        //index 6
        vaultFactory.createNewMarket(50, tokenMIM, depegCCC, beginEpoch, endEpoch, oracleMIM, "y2kMIM_95*SET");

        // Create FEI market
        //index 7
        vaultFactory.createNewMarket(50, tokenFEI, depegAAA, beginEpoch, endEpoch, oracleFEI, "y2kFEI_99*SET");
        //index 8
        vaultFactory.createNewMarket(50, tokenFEI, depegBBB, beginEpoch, endEpoch, oracleFEI, "y2kFEI_97*SET");
        //index 9
        vaultFactory.createNewMarket(50, tokenFEI, depegCCC, beginEpoch, endEpoch, oracleFEI, "y2kFEI_95*SET");

        // Create USDC market
        //index 10
        vaultFactory.createNewMarket(50, tokenUSDC, depegAAA, beginEpoch, endEpoch, oracleUSDC, "y2kUSDC_99*SET");
        //index 11
        vaultFactory.createNewMarket(50, tokenUSDC, depegBBB, beginEpoch, endEpoch, oracleUSDC, "y2kUSDC_97*SET");
        //index 12
        vaultFactory.createNewMarket(50, tokenUSDC, depegCCC, beginEpoch, endEpoch, oracleUSDC, "y2kUSDC_95*SET");

        // Create DAI market
        //index 13
        vaultFactory.createNewMarket(50, tokenDAI, depegAAA, beginEpoch, endEpoch, oracleDAI, "y2kDAI_99*SET");
        //index 14
        vaultFactory.createNewMarket(50, tokenDAI, depegBBB, beginEpoch, endEpoch, oracleDAI, "y2kDAI_97*SET");
        //index 15
        vaultFactory.createNewMarket(50, tokenDAI, depegCCC, beginEpoch, endEpoch, oracleDAI, "y2kDAI_95*SET");
        
        vm.stopPrank();
    }

    function testALLMarketsDeployMore() public {

        testALLMarketsCreation();

        vm.startPrank(admin);

        // Deploy more FRAX market
        vaultFactory.deployMoreAssets(1, beginEpoch + 30 days, endEpoch + 30 days);
        vaultFactory.deployMoreAssets(2, beginEpoch + 30 days, endEpoch + 30 days);
        vaultFactory.deployMoreAssets(3, beginEpoch + 30 days, endEpoch + 30 days);

        // Deploy more MIM market
        vaultFactory.deployMoreAssets(4, beginEpoch + 30 days, endEpoch + 30 days);
        vaultFactory.deployMoreAssets(5, beginEpoch + 30 days, endEpoch + 30 days);
        vaultFactory.deployMoreAssets(6, beginEpoch + 30 days, endEpoch + 30 days);

        // Deploy more FEI market
        vaultFactory.deployMoreAssets(7, beginEpoch + 30 days, endEpoch + 30 days);
        vaultFactory.deployMoreAssets(8, beginEpoch + 30 days, endEpoch + 30 days);
        vaultFactory.deployMoreAssets(9, beginEpoch + 30 days, endEpoch + 30 days);

        // Deploy more USDC market
        vaultFactory.deployMoreAssets(10, beginEpoch + 30 days, endEpoch + 30 days);
        vaultFactory.deployMoreAssets(11, beginEpoch + 30 days, endEpoch + 30 days);
        vaultFactory.deployMoreAssets(12, beginEpoch + 30 days, endEpoch + 30 days);

        // Deploy more DAI market
        vaultFactory.deployMoreAssets(13, beginEpoch + 30 days, endEpoch + 30 days);
        vaultFactory.deployMoreAssets(14, beginEpoch + 30 days, endEpoch + 30 days);
        vaultFactory.deployMoreAssets(15, beginEpoch + 30 days, endEpoch + 30 days);

        vm.stopPrank();
    }

    /*///////////////////////////////////////////////////////////////
                           DEPOSIT functions
    //////////////////////////////////////////////////////////////*/
function Deposit(uint256 _index) public {
        vm.deal(alice, 10 ether);
        vm.deal(bob, 20 ether);
        vm.deal(chad, 100 ether);
        vm.deal(degen, 200 ether);

        address hedge = vaultFactory.getVaults(_index)[0];
        address risk = vaultFactory.getVaults(_index)[1];
        
        Vault vHedge = Vault(hedge);
        Vault vRisk = Vault(risk);

        //ALICE hedge DEPOSIT
        vm.startPrank(alice);
        ERC20(WETH).approve(hedge, 10 ether);
        vHedge.depositETH{value: 10 ether}(endEpoch, alice);
        vm.stopPrank();

        //BOB hedge DEPOSIT
        vm.startPrank(bob);
        ERC20(WETH).approve(hedge, 20 ether);
        vHedge.depositETH{value: 20 ether}(endEpoch, bob);

        assertTrue(vHedge.balanceOf(bob,endEpoch) == 20 ether);
        vm.stopPrank();

        vHedge.totalAssets(endEpoch);
        emit log_named_uint("vHedge.totalAssets(endEpoch)", vHedge.totalAssets(endEpoch));

        //CHAD risk DEPOSIT
        vm.startPrank(chad);
        ERC20(WETH).approve(risk, 100 ether);
        vRisk.depositETH{value: 100 ether}(endEpoch, chad);

        assertTrue(vRisk.balanceOf(chad,endEpoch) == (100 ether));
        vm.stopPrank();

        //DEGEN risk DEPOSIT
        vm.startPrank(degen);
        ERC20(WETH).approve(risk, 200 ether);
        vRisk.depositETH{value: 200 ether}(endEpoch, degen);

        assertTrue(vRisk.balanceOf(degen,endEpoch) == (200 ether));
        vm.stopPrank();

        vRisk.totalAssets(endEpoch);
        emit log_named_uint("vRisk.totalAssets(endEpoch)", vRisk.totalAssets(endEpoch));
    }

    function testDeposit() public {
        vm.deal(alice, 10 ether);
        vm.deal(bob, 20 ether);
        vm.deal(chad, 100 ether);
        vm.deal(degen, 200 ether);

        vm.prank(admin);
        vaultFactory.createNewMarket(50, tokenFRAX, depegAAA, beginEpoch, endEpoch, oracleFRAX, "y2kFRAX_99*SET");

        address hedge = vaultFactory.getVaults(1)[0];
        address risk = vaultFactory.getVaults(1)[1];
        
        Vault vHedge = Vault(hedge);
        Vault vRisk = Vault(risk);

        //ALICE hedge DEPOSIT
        vm.startPrank(alice);
        ERC20(WETH).approve(hedge, 10 ether);
        vHedge.depositETH{value: 10 ether}(endEpoch, alice);
        vm.stopPrank();

        //BOB hedge DEPOSIT
        vm.startPrank(bob);
        ERC20(WETH).approve(hedge, 20 ether);
        vHedge.depositETH{value: 20 ether}(endEpoch, bob);

        assertTrue(vHedge.balanceOf(bob,endEpoch) == 20 ether);
        vm.stopPrank();

        //CHAD risk DEPOSIT
        vm.startPrank(chad);
        ERC20(WETH).approve(risk, 100 ether);
        vRisk.depositETH{value: 100 ether}(endEpoch, chad);

        assertTrue(vRisk.balanceOf(chad,endEpoch) == (100 ether));
        vm.stopPrank();

        //DEGEN risk DEPOSIT
        vm.startPrank(degen);
        ERC20(WETH).approve(risk, 200 ether);
        vRisk.depositETH{value: 200 ether}(endEpoch, degen);

        assertTrue(vRisk.balanceOf(degen,endEpoch) == (200 ether));
        vm.stopPrank();
    }

    function DepositDepeg() public {
        vm.deal(alice, 10 ether);
        vm.deal(bob, 20 ether);
        vm.deal(chad, 100 ether);
        vm.deal(degen, 200 ether);

        vm.startPrank(admin);
        FakeOracle fakeOracle = new FakeOracle(oracleFRAX, 90995265);
        vaultFactory.createNewMarket(50, tokenFRAX, depegAAA, beginEpoch, endEpoch, address(fakeOracle), "y2kFRAX_99*SET");
        vm.stopPrank();

        address hedge = vaultFactory.getVaults(1)[0];
        address risk = vaultFactory.getVaults(1)[1];
        
        Vault vHedge = Vault(hedge);
        Vault vRisk = Vault(risk);

        //ALICE hedge DEPOSIT
        vm.startPrank(alice);
        ERC20(WETH).approve(hedge, 10 ether);
        vHedge.depositETH{value: 10 ether}(endEpoch, alice);

        assertTrue(vHedge.balanceOf(alice,endEpoch) == (10 ether));
        vm.stopPrank();

        //BOB hedge DEPOSIT
        vm.startPrank(bob);
        ERC20(WETH).approve(hedge, 20 ether);
        vHedge.depositETH{value: 20 ether}(endEpoch, bob);

        assertTrue(vHedge.balanceOf(bob,endEpoch) == (20 ether));
        vm.stopPrank();

        //CHAD risk DEPOSIT
        vm.startPrank(chad);
        ERC20(WETH).approve(risk, 100 ether);
        vRisk.depositETH{value: 100 ether}(endEpoch, chad);

        assertTrue(vRisk.balanceOf(chad,endEpoch) == (100 ether));
        vm.stopPrank();

        //DEGEN risk DEPOSIT
        vm.startPrank(degen);
        ERC20(WETH).approve(risk, 200 ether);
        vRisk.depositETH{value: 200 ether}(endEpoch, degen);

        assertTrue(vRisk.balanceOf(degen,endEpoch) == (200 ether));
        vm.stopPrank();
    }

    /*///////////////////////////////////////////////////////////////
                           CONTROLLER functions
    //////////////////////////////////////////////////////////////*/

    function testControllerDepeg() public{

        DepositDepeg();

        address hedge = vaultFactory.getVaults(1)[0];
        address risk = vaultFactory.getVaults(1)[1];

        Vault vHedge = Vault(hedge);
        Vault vRisk = Vault(risk);

        vm.warp(beginEpoch + 10 days);

        emit log_named_int("strike price", vHedge.strikePrice());
        emit log_named_int("oracle price", controller.getLatestPrice(tokenFRAX));

        controller.triggerDepeg(1, endEpoch);

        assertTrue(vHedge.totalAssets(endEpoch) == vRisk.idClaimTVL(endEpoch), "Claim TVL Risk not equal to Total Tvl Hedge");
        assertTrue(vRisk.totalAssets(endEpoch) == vHedge.idClaimTVL(endEpoch), "Claim TVL Hedge not equal to Total Tvl Risk");
    }

    function testControllerEndEpoch() public{

        testDeposit();

        address hedge = vaultFactory.getVaults(1)[0];
        address risk = vaultFactory.getVaults(1)[1];

        Vault vHedge = Vault(hedge);
        Vault vRisk = Vault(risk);

        vm.warp(endEpoch + 1 days);

        emit log_named_int("strike price", vHedge.strikePrice());
        emit log_named_int("oracle price", controller.getLatestPrice(tokenFRAX));

        controller.triggerEndEpoch(1, endEpoch);

        assertTrue(vHedge.totalAssets(endEpoch) == vRisk.idClaimTVL(endEpoch), "Claim TVL not equal");
        //emit log_named_uint("claim tvl", vHedge.idClaimTVL(endEpoch));
        assertTrue(0 == vHedge.idClaimTVL(endEpoch), "Hedge Claim TVL not zero");
    }

    function ControllerEndEpoch(address _token, uint256 _index) public{

        address hedge = vaultFactory.getVaults(_index)[0];
        address risk = vaultFactory.getVaults(_index)[1];

        Vault vHedge = Vault(hedge);
        Vault vRisk = Vault(risk);

        vm.warp(endEpoch + 1 days);

        emit log_named_int("strike price", vHedge.strikePrice());
        emit log_named_int("oracle price", controller.getLatestPrice(_token));

        controller.triggerEndEpoch(_index, endEpoch);

        assertTrue(vHedge.totalAssets(endEpoch) == vRisk.idClaimTVL(endEpoch), "Claim TVL not equal");
        //emit log_named_uint("claim tvl", vHedge.idClaimTVL(endEpoch));
        assertTrue(0 == vHedge.idClaimTVL(endEpoch), "Hedge Claim TVL not zero");
    }


    /*///////////////////////////////////////////////////////////////
                           WITHDRAW functions
    //////////////////////////////////////////////////////////////*/

    function Withdraw() public {

        address hedge = vaultFactory.getVaults(1)[0];
        address risk = vaultFactory.getVaults(1)[1];

        Vault vHedge = Vault(hedge);
        Vault vRisk = Vault(risk);

        uint assets;

        //ALICE hedge WITHDRAW
        vm.startPrank(alice);
        assets = vHedge.balanceOf(alice,endEpoch);
        vHedge.withdraw(endEpoch, assets, alice, alice);

        assertTrue(vHedge.balanceOf(alice,endEpoch) == 0);
        uint256 entitledShares = vHedge.beforeWithdraw(endEpoch, assets);
        assertTrue(entitledShares - vHedge.calculateWithdrawalFeeValue(entitledShares) == ERC20(WETH).balanceOf(alice));

        vm.stopPrank();

        //BOB hedge WITHDRAW
        vm.startPrank(bob);
        assets = vHedge.balanceOf(bob,endEpoch);
        vHedge.withdraw(endEpoch, assets, bob, bob);
        
        assertTrue(vHedge.balanceOf(bob,endEpoch) == 0);
        entitledShares = vHedge.beforeWithdraw(endEpoch, assets);
        assertTrue(entitledShares - vHedge.calculateWithdrawalFeeValue(entitledShares) == ERC20(WETH).balanceOf(bob));

        vm.stopPrank();

        emit log_named_uint("hedge balance", ERC20(WETH).balanceOf(address(vHedge)));

        //CHAD risk WITHDRAW
        vm.startPrank(chad);
        assets = vRisk.balanceOf(chad,endEpoch);
        vRisk.withdraw(endEpoch, assets, chad, chad);

        assertTrue(vRisk.balanceOf(chad,endEpoch) == 0);
        entitledShares = vRisk.beforeWithdraw(endEpoch, assets);
        assertTrue(entitledShares - vRisk.calculateWithdrawalFeeValue(entitledShares) == ERC20(WETH).balanceOf(chad));

        vm.stopPrank();

        //DEGEN risk WITHDRAW
        vm.startPrank(degen);
        assets = vRisk.balanceOf(degen,endEpoch);
        vRisk.withdraw(endEpoch, assets, degen, degen);

        assertTrue(vRisk.balanceOf(degen,endEpoch) == 0);
        entitledShares = vRisk.beforeWithdraw(endEpoch, assets);
        assertTrue(entitledShares - vRisk.calculateWithdrawalFeeValue(entitledShares) == ERC20(WETH).balanceOf(degen));

        vm.stopPrank();

        emit log_named_uint("risk balance", ERC20(WETH).balanceOf(address(vRisk)));

    }

    function testWithdrawDepeg() public {
        testControllerDepeg();

        address hedge = vaultFactory.getVaults(1)[0];
        address risk = vaultFactory.getVaults(1)[1];

        Vault vHedge = Vault(hedge);
        Vault vRisk = Vault(risk);

        uint assets;

        //ALICE hedge WITHDRAW
        vm.startPrank(alice);
        assets = vHedge.balanceOf(alice,endEpoch);
        vHedge.withdraw(endEpoch, assets, alice, alice);

        assertTrue(vHedge.balanceOf(alice,endEpoch) == 0);
        uint256 entitledShares = vHedge.beforeWithdraw(endEpoch, assets);
        assertTrue(entitledShares - vHedge.calculateWithdrawalFeeValue(entitledShares) == ERC20(WETH).balanceOf(alice));

        vm.stopPrank();

        //BOB hedge WITHDRAW
        vm.startPrank(bob);
        assets = vHedge.balanceOf(bob,endEpoch);
        vHedge.withdraw(endEpoch, assets, bob, bob);
        
        assertTrue(vHedge.balanceOf(bob,endEpoch) == 0);
        entitledShares = vHedge.beforeWithdraw(endEpoch, assets);
        assertTrue(entitledShares - vHedge.calculateWithdrawalFeeValue(entitledShares) == ERC20(WETH).balanceOf(bob));

        vm.stopPrank();

        emit log_named_uint("hedge balance", ERC20(WETH).balanceOf(address(vHedge)));

        //CHAD risk WITHDRAW
        vm.startPrank(chad);
        assets = vRisk.balanceOf(chad,endEpoch);
        vRisk.withdraw(endEpoch, assets, chad, chad);

        assertTrue(vRisk.balanceOf(chad,endEpoch) == 0);
        entitledShares = vRisk.beforeWithdraw(endEpoch, assets);
        assertTrue(entitledShares - vRisk.calculateWithdrawalFeeValue(entitledShares) == ERC20(WETH).balanceOf(chad));

        vm.stopPrank();

        //DEGEN risk WITHDRAW
        vm.startPrank(degen);
        assets = vRisk.balanceOf(degen,endEpoch);
        vRisk.withdraw(endEpoch, assets, degen, degen);

        assertTrue(vRisk.balanceOf(degen,endEpoch) == 0);
        entitledShares = vRisk.beforeWithdraw(endEpoch, assets);
        assertTrue(entitledShares - vRisk.calculateWithdrawalFeeValue(entitledShares) == ERC20(WETH).balanceOf(degen));

        vm.stopPrank();

        emit log_named_uint("risk balance", ERC20(WETH).balanceOf(address(vRisk)));
    }
}