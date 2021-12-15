// SPDX-License-Identifier: MIT
//
// Author: theblockchain.eth
//
// Disclaimer: THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE 
//             WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE 
//             LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
//             OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// TLDR:       Test it and DYOR, its free MIT licensed code y'know....
//
//  -_----_------------_------_---------------_-----------_-------------_------------------_----_-----
//  |-|_-|-|__----___-|-|__--|-|--___----___-|-|-__--___-|-|__----__-_-(_)-_-__-------___-|-|_-|-|__--
//  |-__||-'_-\--/-_-\|-'_-\-|-|-/-_-\--/-__||-|/-/-/-__||-'_-\--/-_`-||-||-'_-\-----/-_-\|-__||-'_-\-
//  |-|_-|-|-|-||--__/|-|_)-||-||-(_)-||-(__-|---<-|-(__-|-|-|-||-(_|-||-||-|-|-|-_-|--__/|-|_-|-|-|-|
//  -\__||_|-|_|-\___||_.__/-|_|-\___/--\___||_|\_\-\___||_|-|_|-\__,_||_||_|-|_|(_)-\___|-\__||_|-|_|
//  --------------------------------------------------------------------------------------------------
//
// Features:
//  - Highly optimised and super cheap gas for both deployment AND minting!
//  - Set supply, price, and maximum mints per txn set and locked at contract deployment
//  - Updatable metadata URI
//  - Updatable dev team wallet address for withdrawal
//  - Multiple sales states (paused, presale, public sale)
//  - Upload lists to whitelist
//  - Highly optimised and cheap gas for deployment AND minting
//  - Feel free to scrub these comments but if you can credit, please do.
//  - Likewise, a commission element is within a function; this contract took me time 
//      and I would appreciate if this remained in the deployment to compensate said effort; 
//      good luck and I thank you in advance!
// 
// Efficiency / Estimations (provided for reference, not a guarantee): 
//
// Approx Deployment: 2236892 Gas              || @ 90 Gwei = 0.145945 ETH || @ $4000 ETH/USD = $584.00 || 
// Update Sale State: 28721 Gas                || @ 90 Gwei = 0.001874 ETH || @ $4000 ETH/USD = $7.50   || 
// 1st Mint, Minting 1 Token: 78379 Gas        || @ 90 Gwei = 0.005114 ETH || @ $4000 ETH/USD = $20.50  || 
// 2nd Mint, Minting 1 Token: 61279 Gas        || @ 90 Gwei = 0.004000 ETH || @ $4000 ETH/USD = $16.00  || 
// 1st Mint, Minting 10 Tokens: 305089 Gas     || @ 90 Gwei = 0.019936 ETH || @ $4000 ETH/USD = $79.75  || Approx. $8.00 each
// 2nd Mint, Minting 10 Tokens: 287989 Gas     || @ 90 Gwei = 0.018797 ETH || @ $4000 ETH/USD = $75.25  || Approx. $7.50 each
//
// Steps: 
//   1. Update the contract name
//   2. Ensure you're passing in _tokenName, _tokenNameCode, _maxTokens, _mintPrice, _project_wallet
//         _tokenName      = Full Name of the Token (i.e. "My Token") 
//         _tokenNameCode  = Code Name of the Token (i.e. "MTKN")  
//         _maxTokens      = Supply Limit (i.e. 10000)  
//         _mintPrice      = Price in WEI (i.e. for 0.02 ETH, its 20000000000000000)
//                           FYI: If you're using JS tools for deployment or migrations, you may need 
//                                to use web3.utils.toWei and web3.utils.toBN to handle these inputs
//         _project_wallet = Where to withdraw funds to (refrain from ENS names)
//   3. Test it locally or via Remix
//   4. Test it some more...
//
// I'd highly recommend using Hardhat, Truffle, or Remix to automate tests in Javascript
// Unit testing all functions and behaviours
// I offer test suites but I'm not open-sourcing these parts
// However, I have tested this code to my needs as a generally repurposeable ERC721 contract
// I am personally happy with the quality but its not provided as a guarantee (see disclaimer)


pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract optimisedContract is ERC721, Ownable {

    using Counters for Counters.Counter;
    
    struct ConfigStateData {
        
        uint8 maxTokensPerTxn;
        uint16 maxTokens;
        saleState salestate;
        string baseUri;
        uint256 mintPrice;
        address projectWallet;
        
    }

    enum saleState { paused, presale, publicsale }
    ConfigStateData public myContractStateData;

    Counters.Counter private _tokenIdCounter;
    mapping(address => bool) public whitelistedAddresses;

    constructor( string memory _tokenName, string memory _tokenNameCode, uint16 _maxTokens, uint256 _mintPrice, address _project_wallet) 
        ERC721(  _tokenName, _tokenNameCode) {

            myContractStateData.maxTokens =  _maxTokens;
            myContractStateData.mintPrice =  _mintPrice;
            myContractStateData.projectWallet =  _project_wallet;

            // Cap low to stop out of gas issues, 10 ideal, 20 is pushing it....
            myContractStateData.maxTokensPerTxn =  10;
            // Add sender to whitelist by default...
            whitelistedAddresses[msg.sender] = true;
            // Increment the counter to start at 1, not 0...
            _tokenIdCounter.increment();

    }

    function setDevWalletAddress(address _project_wallet) external onlyOwner {
        myContractStateData.projectWallet = _project_wallet;
    }

    function setSaleState(uint _statusId) external onlyOwner {
        myContractStateData.salestate = saleState(_statusId);
    }

    function setBaseUri(string memory _baseUri) external onlyOwner {
        myContractStateData.baseUri = _baseUri;
    }

    function appendToWhitelist(address[] calldata _whitelist_addr_list) external onlyOwner {
        for (uint i = 0; i < _whitelist_addr_list.length; i++) {
            whitelistedAddresses[_whitelist_addr_list[i]] = true;
        }
    }

    function mint(uint8 _number_to_mint) public payable {

        uint256 nextMintId = _tokenIdCounter.current();
        uint256 activeSaleStateInt = uint(myContractStateData.salestate);
        
        require(activeSaleStateInt > 0, "Minting Paused");
        require(msg.value >= (myContractStateData.mintPrice * uint(_number_to_mint)), "Under paid");
        require(_number_to_mint <= myContractStateData.maxTokensPerTxn, "Being greedy");
        require(nextMintId <= (myContractStateData.maxTokens - uint(_number_to_mint)) , "Not enough supply");
        
        if (activeSaleStateInt == 1){

            require(whitelistedAddresses[msg.sender] == true, "Not whitelisted");

            for (uint i = 0; i < _number_to_mint; i++) {
                _mint(msg.sender, nextMintId + i);
                _tokenIdCounter.increment();
            }
            
            delete(whitelistedAddresses[msg.sender]);

        } else {

            for (uint i = 0; i < _number_to_mint; i++) {
                _mint(msg.sender, nextMintId + i);
                _tokenIdCounter.increment();
            }

        }

        delete nextMintId;
        delete activeSaleStateInt;
    }

    function withdraw() external onlyOwner {

        address payable _project_devs = payable(myContractStateData.projectWallet);
        address payable _contract_devs = payable(0x0D045c9f200048BBb54569270E1a87AD599f6A71);

        _contract_devs.transfer((address(this).balance / 100) * 10);
        _project_devs.transfer(address(this).balance);

    }

    function _baseURI() internal view override returns (string memory) {
        return myContractStateData.baseUri;
    }

}