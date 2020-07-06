import { initialize } from "zokrates-js";
let Web3 = require('web3');
let solc = require('solc');  // solidity compiler bindings
let fs = require('fs-extra');


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
    location: path 
  };
}

initialize().then((zokratesProvider) => {
  //const compileOutput = zokratesProvider.compile( "import \"hashes/sha256/512bitPacked\" as sha256packed\n \n def main(private field a, private field b, private field c, private field d) -> (field):\n field[2] h = sha256packed([a, b, c, d])\n h[0] == 263561599766550617289250058199814760685\n h[1] == 65303172752238645975888084098459749904\n return 1\n", "main", importResolver);
  
let compileOutput;
try{
  compileOutput = JSON.parse(fs.readFileSync("compile.out"));
} catch(e) {
  console.log("Compiling ...");
  const compileOutput = zokratesProvider.compile( "import \"hashes/sha256/512bitPacked\" as sha256packed\n \n def main(private field a, private field b, private field c, private field d) -> (field):\n field[2] h = sha256packed([a, b, c, d])\n h[0] == 263561599766550617289250058199814760685\n h[1] == 65303172752238645975888084098459749904\n return 1\n", "main", importResolver);
  writeObject("compile.out",compileOutput);
}

let setupOutput;
try{
  setupOutput = JSON.parse(fs.readFileSync("setup.out"));
} catch(e) {
  setupOutput = zokratesProvider.setup(compileOutput.program);
  writeObject("setup.out",setupOutput);
}

  
  const verifier = zokratesProvider.exportSolidityVerifier(
    setupOutput.vk,
    true
  );
  writeObject("verifier.out",verifier);

  // compile verifier
  var input = {
    language: 'Solidity',
    sources: {
      'Verifier.sol': {
        content: verifier
      }
    },
    settings: {
      outputSelection: {
        '*': {
          '*': ['*']
        }
      }
    }
  };

  // structure of compile result: https://solidity.readthedocs.io/en/v0.6.6/using-the-compiler.html
  let compiled = JSON.parse(solc.compile(JSON.stringify(input)));
  fs.outputJsonSync('Verifier.json', compiled.contracts['Verifier.sol']['Verifier']);

  // deploy verifier on ganache
  let web3 = new Web3(new Web3.providers.HttpProvider('http://localhost:8545'), null, { transactionConfirmationBlocks: 1 /* This is the critical part */ });
  let source = fs.readFileSync("Verifier.json");
  let contract = JSON.parse(source);

  let abi = contract.abi;
  let code = '0x' + contract.evm.bytecode.object;

  let Contract = web3.eth.Contract(abi);
  Contract.options.data = code;

  Contract.deploy()
  .send({
    from: '0x6E70D2B6d2368bbEA614408DD1aF17DB2CE1970c', // add address here
    gas: 1500000,
    gasPrice: '30000000000000'
  })
  .then(function(newContractInstance){
      console.log(newContractInstance.options.address) // instance with the new contract address
  });

});
