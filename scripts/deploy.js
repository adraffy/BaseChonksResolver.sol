import { FoundryDeployer } from "@adraffy/blocksmith";
import { createInterface } from "node:readline/promises";

const rl = createInterface({
	input: process.stdin,
	output: process.stdout,
});

let provider = await rl.question("Network (default mainnet, S = sepolia, <url>): ");
if (/^(|m|mainnet)$/i.test(provider)) {
	provider = "https://eth.drpc.org";
} else if (/^t|testnet|s|sepolia$/i.test(provider)) {
	provider = "https://sepolia.drpc.org";
}
console.log(`Provider: ${provider}`);

const deployer = await FoundryDeployer.load({
	provider,
	privateKey: await rl.question("Private Key (empty to simulate): "),
});

const deployable = await deployer.prepare({
	file: "BaseChonksResolver",
});

if (deployer.privateKey) {
	await rl.question("Ready? (abort to stop) ");
	await deployable.deploy();
	const apiKey = await rl.question("Etherscan API Key: ");
	if (apiKey) {
		await deployable.verifyEtherscan({ apiKey });
	}
}

rl.close();
