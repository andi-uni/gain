const { initialize } = require("zokrates-js-node");

function writeObject(filename,object) {
  fs = require('fs');
  fs.writeFileSync(filename, JSON.stringify(object));
  console.log('Write to ...');
  console.log(filename);
} 

function readObject(filename) {
  fs = require('fs')
  return JSON.parse(fs.readFileSync(filename, 'utf8'));
}

function importResolver(location, path) {
  // implement your resolving logic here
  return { 
    source: "def main() -> (): return", 
    location: path 
  };
}

initialize().then((zokratesProvider) => {
  contract = readObject("../contracts/merkleTree.json");
  console.log(contract)
  const compileOutput = zokratesProvider.compile(contract, "main", importResolver);
  writeObject("compile.out",compileOutput);
  const setupOutput = zokratesProvider.setup(compileOutput.program);
  writeObject("setup.out",setupOutput);
  const verifier = zokratesProvider.exportSolidityVerifier(
    setupOutput.vk,
    true
  );
  writeObject("verifier.out",verifier);
}).catch((err) => console.log(err));
