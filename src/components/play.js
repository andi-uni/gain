import { initialize } from "zokrates-js-node";

let Web3 = require('web3');
let solc = require('solc');  // solidity compiler bindings
let fs = require('fs-extra');

function writeObject(filename,object) {
    fs.writeFileSync(filename, JSON.stringify(object));
    console.log('Write to ...');
    console.log(filename);
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

    fs.writeFileSync('verifier.sol', verifier)
  
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
  
  });