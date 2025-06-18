import { Foundry } from "@adraffy/blocksmith";
import { after, test } from "node:test";
import assert from "node:assert/strict";

test("BaseChonksResolver", async (T) => {
	const foundry = await Foundry.launch({
		infoLog: true,
		fork: "https://eth.drpc.org",
	});
	after(foundry.shutdown);

	const BaseChonksResolver = await foundry.deploy({
		file: "BaseChonksResolver",
	});

	const BASENAME = "base.chonks";
	const CHAIN_ID_BASE = 8453;

	await foundry.overrideENS({
		name: BASENAME,
		owner: null,
		resolver: BaseChonksResolver,
	});

	await T.test("addr(basename) = nft", async () => {
		const r = await requireResolver(`${BASENAME}`);
		assert.equal(
			await r.getAddress(CHAIN_ID_BASE),
			"0x07152bfde079b5319e5308C43fB1Dbc9C76cb4F9"
		);
	});

	for (const id of [1, 2, 1337, 4444]) {
		await T.test(`subdomain: ${id}`, async () => {
			const [r0, r1] = await Promise.all([
				requireResolver(`${id}.chonks.base.eth`),
				requireResolver(`${id}.${BASENAME}`),
			]);
			const [a0, a1] = await Promise.all([
				r0.getAddress(),
				r1.getAddress(CHAIN_ID_BASE),
			]);
			assert(a0, "a0");
			assert(a1, "a1");
			assert.equal(a0, a1);
		});
	}

	async function requireResolver(name) {
		const resolver = await foundry.provider.getResolver(name);
		if (!resolver) throw new Error(`expect resolver: ${name}`);
		return resolver;
	}
});
