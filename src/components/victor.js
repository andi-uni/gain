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
    "def main(private field a) -> (field): return a",
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
