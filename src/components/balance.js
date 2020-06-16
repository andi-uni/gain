const Web3 = require('web3')

const acc = require('./read-env-vars.js')

const web3 = new Web3(acc.infura)

web3.eth.getBalance(acc.account1, (err, wei) => { console.log('Account1: ' + web3.utils.fromWei(wei, 'ether')) + 'Ether' })
web3.eth.getBalance(acc.account2, (err, wei) => { console.log('Account2: ' + web3.utils.fromWei(wei, 'ether')) + 'Ether'})
