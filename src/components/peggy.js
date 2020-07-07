import { initialize } from "zokrates-js-node";
let fs = require('fs-extra');

let VICTOR_ADR = '0xc31Eb6E317054A79bb5E442D686CB9b225670c1D'
let PEGGY_ADR = '0x97026a8157f39101aefc4A81496C161a6b1Ce46A'

function writeObject(filename,object) {
  fs.writeFileSync(filename, JSON.stringify(object));
  console.log('Write to ...');
  console.log(filename);
} 

function readObject(filename) {
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
  let witness = zokratesProvider.computeWitness(compileOutput, ['0', '0', '0', '5']);
  let setup = readObject("setup.out");
  let provingKey = setup.pk;

  let proof = zokratesProvider.generateProof(compileOutput.program, witness.witness, provingKey) // proving Key is handed over from victor
  writeObject("proof.out",proof);
});
