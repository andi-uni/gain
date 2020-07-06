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
  const compileOutput = zokratesProvider.compile( "import \"hashes/sha256/512bitPacked\" as sha256packed\n \n def main(private field a, private field b, private field c, private field d) -> (field):\n field[2] h = sha256packed([a, b, c, d])\n h[0] == 263561599766550617289250058199814760685\n h[1] == 65303172752238645975888084098459749904\n return 1\n", "main", importResolver);

  writeObject("compile.out",compileOutput);
  //console.log(readObject("compile.out"));
  const setupOutput = zokratesProvider.setup(compileOutput.program);
  writeObject("setup.out",setupOutput);
  const verifier = zokratesProvider.exportSolidityVerifier(
    setupOutput.vk,
    true
  );
  writeObject("verifier.out",verifier);
});
