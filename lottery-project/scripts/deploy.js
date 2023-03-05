const hre = require("hardhat");

async function main() {
	const Lottery = await hre.ethers.getContractFactory("Lottery");
	const lottery = await Lottery.deploy(
		"0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9", // VRF Coordinator
		"0xa36085F69e2889c224210F603D836748e7dC0088", // LINK Token
		"0x8C7382F9D8f56b33781fE506E897a4F1e2d17255", // Key Hash
		hre.ethers.utils.parseEther("0.1") // Fee
	);

	await lottery.deployed();

	console.log("Lottery deployed to:", lottery.address);
}

main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error);
		process.exit(1);
	});
