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


  // let compileOutput = fs.readFileSync("out");
  // try{
  //   compileOutput = JSON.parse(fs.readFileSync("compile.out"));
  // } catch(e) {
  //   console.log("Compiling ...");
  //   compileOutput = zokratesProvider.compile(
  //     "import \"hashes/sha256/512bitPacked\" as sha256packed\n \n def main(private field a, private field b, private field c, private field d) -> (field):\n field[2] h = sha256packed([a, b, c, d])\n h[0] == 263561599766550617289250058199814760685\n h[1] == 65303172752238645975888084098459749904\n return 1\n",
  //     "main",
  //     importResolver
  //   );
  //   writeObject("compile.out",compileOutput);
  // }

  // let w_input = [275959064870317583127718872284777314433, 174620349730531069369659418404393127590, 26161666508797006669919685854854985452, 311280584607358947491925431529540842530, 1, 0, 111861671051826229608133492736489986610, 71652505371284586136584048810280214156, 158728772758170246975894961339923238846, 37250294219555495615670710949664303020];
  // let witness;
  // try {
  //   witness = readObject("witness.out");
  // } catch (error) {
  //   witness = zokratesProvider.computeWitness(compileOutput, w_input);
  //   writeObject("witness.out", witness);
  // }

  // let setup = readObject("setup.out");
  // let provingKey = setup.pk;


  // let proof;
  // try {
  //   proof = readObject("proof.out")
  // } catch (error) {
  //   proof = zokratesProvider.generateProof(compileOutput.program, witness.witness, provingKey) // proving Key is handed over from victor
  //   writeObject("proof.out",proof);
  // }

  let proof = fs.readFileSync('proof.json')
  
  let contractAddress = readObject('contractAddress.out');
  console.log(contractAddress)

  let web3 = new Web3(new Web3.providers.HttpProvider('http://localhost:8545'), null, { transactionConfirmationBlocks: 1 /* This is the critical part */ });
  let source = fs.readFileSync("verifier.json");
  let contract = JSON.parse(source);

  let Contract = web3.eth.Contract(contract.abi, contractAddress);

  fs.outputJsonSync('proof.json', JSON.parse(proof))

  let p = JSON.parse(proof).proof
  console.log(contract.abi)
  // console.log(JSON.parse(proof))

  let inputs = JSON.parse(proof).inputs;

  // console.log(inputs)

  let a0 = web3.eth.abi.encodeParameter('uint256',p.a[0])
  let a1 = web3.eth.abi.encodeParameter('uint256',p.a[1])

  let b00 = web3.eth.abi.encodeParameter('uint256',p.b[0][0])
  let b01 = web3.eth.abi.encodeParameter('uint256',p.b[0][1])
  let b10 = web3.eth.abi.encodeParameter('uint256',p.b[1][0])
  let b11 = web3.eth.abi.encodeParameter('uint256',p.b[1][1])

  let c0 = web3.eth.abi.encodeParameter('uint256',p.c[0])
  let c1 = web3.eth.abi.encodeParameter('uint256',p.c[1])

  let i0 = web3.eth.abi.encodeParameter('uint256',inputs[0])
  let i1 = web3.eth.abi.encodeParameter('uint256',inputs[1])
  let i2 = web3.eth.abi.encodeParameter('uint256',inputs[2])
  let i3 = web3.eth.abi.encodeParameter('uint256',inputs[3])
  let i4 = web3.eth.abi.encodeParameter('uint256',inputs[4])

  // console.log(p)
  // console.log(inputs)

  Contract.methods.verifyTx([a0, a1], 
                            [[b00, b01], [b10, b11]], 
                            [c0, c1], 
                            [i0, i1, i2, i3, i4])
  .send({
    from: PEGGY_ADR,
    gas: 6721975,
    gasPrice: 1000
  })
  .then(receipt => {
    console.log(receipt)
  });
  // for (let i in Contract.methods.contract) console.log(i)
});
