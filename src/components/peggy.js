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
    location: path,
  };
}

initialize().then((zokratesProvider) => {
  // we have to initialize the wasm module before calling api functions
  const compileOutput = zokratesProvider.compile(
    "import \"hashes/sha256/512bitPacked\" as sha256packed\n \n def main(private field a, private field b, private field c, private field d) -> (field):\n field[2] h = sha256packed([a, b, c, d])\n h[0] == 263561599766550617289250058199814760685\n h[1] == 65303172752238645975888084098459749904\n return 1\n",
    "main",
    importResolver
  );
  console.log(compileOutput)
  witness = zokratesProvider.computeWitness(compileOutput, ['0', '0', '0', '5']); //Was sollte hier übergeben werden?
  // output comprises witness and output
  fs = require('fs')
  proovingKey = 0
  fs.readFile('./pk', 'utf8', function (err,data) {
    if (err) {
      return console.log(err);
    }
    provingKey = data;
    console.log(data);
    proof = zokratesProvider.generateProof(compileOutput.program, witness.witness, proovingKey) // proving Key is handed over from victor
  });
});
