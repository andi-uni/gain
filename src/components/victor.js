const { initialize } = require("zokrates-js-node");

function importResolver(location, path) {
  // implement your resolving logic here
  console.log("im here importResolver");
  zokratesProvider.setup(program);
  zokratesProvider.exportSolidityVerifier(vk, abi);

  return {
    source: "def main() -> (): return",
    location: path,
  };
}

initialize().then((zokratesProvider) => {
  // we have to initialize the wasm module before calling api functions
  console.log("im here init");

  const compileOutput = zokratesProvider.compile(
    "import \"hashes/sha256/512bitPacked\" as sha256packed\n \n def main(private field a, private field b, private field c, private field d) -> (field):\n h = sha256packed([a, b, c, d])\n h[0] == 263561599766550617289250058199814760685\n h[1] == 65303172752238645975888084098459749904\n return 1\n",
    "main",
    importResolver
  );

  console.log(compileOutput);
  const setupOutput = zokratesProvider.setup(compileOutput.program);
  console.log(setupOutput);
  const verifier = zokratesProvider.exportSolidityVerifier(
    setupOutput.vk,
    true
  );
});
