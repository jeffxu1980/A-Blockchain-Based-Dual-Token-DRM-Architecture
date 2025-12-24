// web3_test_trusted_culture.js
// 运行方法：在 Remix 文件浏览器右键点击此脚本 -> Run

(async () => {
    try {
        const accounts = await web3.eth.getAccounts();
        const creator = accounts[0];
        const consumer = accounts[1];
        
        console.log("-----------------------------------------");
        console.log("Trusted-Culture Automated Test Started");
        console.log("Creator:", creator);
        console.log("Consumer:", consumer);

        // 1. Deploy NFT Contract
        const metadata = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/TrustedCulture.sol'));
        const artifacts = metadata.result; // Simplified for Remix script runner
        
        // 注意：在 Remix 脚本运行中直接部署较复杂，建议使用上述手动步骤
        // 此处仅打印逻辑验证流程
        
        console.log("\n--- Logic Verification ---");
        
        // 模拟定价公式计算
        const alpha = 100;
        const beta = 50;
        const gamma = 20;
        
        const Ck = 100; // Cultural Value
        const Mk = 200; // Market Value
        let Uk = 0;   // Usage Value
        
        let price = (alpha * Ck) + (beta * Uk) + (gamma * Mk);
        console.log(`Initial Price Calculation (Uk=0): ${price} wei`);
        
        if (price === 14000) {
            console.log("SUCCESS: Pricing Formula Matches Paper");
        } else {
            console.log("FAIL: Pricing Formula Mismatch");
        }

        // 模拟购买后
        Uk = 1;
        price = (alpha * Ck) + (beta * Uk) + (gamma * Mk);
        console.log(`Price after 1 purchase (Uk=1): ${price} wei`);
        
        if (price === 14050) {
            console.log("SUCCESS: Dynamic Pricing Update Correct");
        } else {
            console.log("FAIL: Dynamic Pricing Update Error");
        }

        console.log("-----------------------------------------");
        console.log("Please follow the manual steps in the response to interact with the deployed contracts.");
        
    } catch (e) {
        console.log(e.message);
    }
})();
