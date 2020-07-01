const { initialize } = require("zokrates-js-node");

function importResolver(location, path) {
  // implement your resolving logic here

  return {
    source: "def main() -> (): return",
    location: path,
  };
}

initialize().then((zokratesProvider) => {
  // we have to initialize the wasm module before calling api functions
  const compileOutput = zokratesProvider.compile(
    "def main(private field a) -> (field): return a",
    "main",
    importResolver
  );
  zokratesProvider.computeWitness(compileOutput.abi, 4); //Was sollte hier übergeben werden?
});
