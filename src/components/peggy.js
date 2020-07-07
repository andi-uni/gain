import { initialize } from "zokrates-js-node";
let fs = require('fs-extra');
let Web3 = require('web3');

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
  let compileOutput;
  try{
    compileOutput = JSON.parse(fs.readFileSync("compile.out"));
  } catch(e) {
    console.log("Compiling ...");
    compileOutput = zokratesProvider.compile(
      "import \"hashes/sha256/512bitPacked\" as sha256packed\n \n def main(private field a, private field b, private field c, private field d) -> (field):\n field[2] h = sha256packed([a, b, c, d])\n h[0] == 263561599766550617289250058199814760685\n h[1] == 65303172752238645975888084098459749904\n return 1\n",
      "main",
      importResolver
    );
    writeObject("compile.out",compileOutput);
  }

  let witness;
  try {
    witness = readObject("witness.out");
  } catch (error) {
    witness = zokratesProvider.computeWitness(compileOutput, ['0', '0', '0', '5']);
    writeObject("witness.out", witness);
  }

  let setup = readObject("setup.out");
  let provingKey = setup.pk;


  let proof;
  try {
    proof = readObject("proof.out")
  } catch (error) {
    proof = zokratesProvider.generateProof(compileOutput.program, witness.witness, provingKey) // proving Key is handed over from victor
    writeObject("proof.out",proof);
  }
  
  let contractAddress = readObject('contractAddress.out');
  let web3 = new Web3(new Web3.providers.HttpProvider('http://localhost:8545'), null, { transactionConfirmationBlocks: 1 /* This is the critical part */ });
  let source = fs.readFileSync("Verifier.json");
  let contract = JSON.parse(source);

  let Contract = web3.eth.Contract(contract.abi, contractAddress);

  fs.outputJsonSync('proof.json', JSON.parse(proof))

  let p = JSON.parse(proof).proof
  // console.log(contract.abi)
  // console.log(JSON.parse(proof))

  let inputs = JSON.parse(proof).inputs;


  // console.log(uint256(inputs))
  // // 'verifyTx(((p.a[0], p.a[1]),([p.b[0][0], p.b[0][1]],[p.b[1][0], p.b[1][1]]) (p.c[0]),p.c[1])),uint256[1])'

  // console.log([p.a[0], p.a[1]], [[p.b[0][0], p.b[0][1]], [p.b[1][0], p.b[1][1]]], [p.c[0] ,p.c[1]], inputs)

  //let x = ((0,0),([2,2], [2,2]),(0,0)),[0]

  // (p.a[0], p.a[1]),([p.b[0][0],p.b[0][1]], [p.b[1][0],p.b[1][1]]),(p.c[0] ,p.c[1])
  let a0 = web3.eth.abi.encodeParameter('uint256',p.a[0])
  let a1 = web3.eth.abi.encodeParameter('uint256',p.a[1])

  let b00 = web3.eth.abi.encodeParameter('uint256',p.b[0][0])
  let b01 = web3.eth.abi.encodeParameter('uint256',p.b[0][1])
  let b10 = web3.eth.abi.encodeParameter('uint256',p.b[1][0])
  let b11 = web3.eth.abi.encodeParameter('uint256',p.b[1][1])

  let c0 = web3.eth.abi.encodeParameter('uint256',p.c[0])
  let c1 = web3.eth.abi.encodeParameter('uint256',p.c[1])

  let inp = web3.eth.abi.encodeParameter('uint256',inputs)

  Contract.methods.verifyTx([[a0, a1], 
                            [[b00, b01], [b10, b11]], 
                            [c0, c1]], 
                            [inp])
  .send({
    from: PEGGY_ADR,
    gas: 100000,
    gasPrice: 1000
  });
  // for (let i in Contract.methods.contract) console.log(i)



  
});



// UnhandledPromiseRejectionWarning: Error: types/values length mismatch 
// (count={"types":2,"values":4}, 
// value={"types":[{"components":[{"components":[
//   {"internalType":"uint256","name":"X","type":"uint256"},
//   {"internalType":"uint256","name":"Y","type":"uint256"}],
//   "internalType":"struct Pairing.G1Point","name":"a","type":"tuple"},
//   {"components":[{"internalType":"uint256[2]","name":"X","type":"uint256[2]"},
//   {"internalType":"uint256[2]","name":"Y","type":"uint256[2]"}],
//   "internalType":"struct Pairing.G2Point","name":"b","type":"tuple"},
//   {"components":[{"internalType":"uint256","name":"X","type":"uint256"},
//   {"internalType":"uint256","name":"Y","type":"uint256"}],
//   "internalType":"struct Pairing.G1Point","name":"c","type":"tuple"}],
//   "internalType":"struct Verifier.Proof","name":"proof","type":"tuple"},
//   {"internalType":"uint256[1]","name":"input","type":"uint256[1]"}],
//   "values":[
//     "0x1d3f567420a9f5508ba79005719575ad52a417befedaa9f741da77cd077e7295",
//     "0x1d3f567420a9f5508ba79005719575ad52a417befedaa9f741da77cd077e7295",
//     "0x1d3f567420a9f5508ba79005719575ad52a417befedaa9f741da77cd077e7295",
//     "0x1d3f567420a9f5508ba79005719575ad52a417befedaa9f741da77cd077e7295"]}, 
//     version=4.0.32)