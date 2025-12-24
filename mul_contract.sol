// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// ==========================================
// 1. Ownership Token (NFT) Contract
// [cite: 46, 47] 对应论文中的 Ownership Contract
// ==========================================
contract CulturalAssetNFT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // 记录资产的静态文化价值 (Ck) 和创建者
    struct AssetMetadata {
        uint256 culturalValue; // C_k [cite: 55]
        address creator;
        uint256 timestamp;
    }

    mapping(uint256 => AssetMetadata) public assetMetadata;
    address public platformContract; // 允许平台合约操作

    event AssetMinted(uint256 indexed tokenId, address creator, string ipfsHash, uint256 culturalValue);

    constructor() ERC721("TrustedCultureNFT", "TCNFT") Ownable(msg.sender) {}

    // 设置平台合约地址
    function setPlatformContract(address _platform) external onlyOwner {
        platformContract = _platform;
    }

    // [cite: 36] Minting Contract logic
    function mintAsset(address player, string memory tokenURI, uint256 _culturalValue)
        public
        returns (uint256)
    {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _mint(player, newItemId);
        _setTokenURI(newItemId, tokenURI);

        assetMetadata[newItemId] = AssetMetadata({
            culturalValue: _culturalValue,
            creator: player,
            timestamp: block.timestamp
        });

        emit AssetMinted(newItemId, player, tokenURI, _culturalValue);
        return newItemId;
    }
    
    // 获取资产元数据
    function getAssetData(uint256 tokenId) external view returns (uint256, address) {
        return (assetMetadata[tokenId].culturalValue, ownerOf(tokenId));
    }
}

// ==========================================
// 2. Access Token (FT) & Pricing Protocol
// [cite: 21, 37, 53] 对应 Dual-Token Protocol 和 Pricing Engine
// ==========================================
contract TrustedCulturePlatform is Ownable {
    CulturalAssetNFT public nftContract;

    // [cite: 55] 定价参数权重 (由 DAO/Admin 管理)
    uint256 public alpha = 100; // 权重: 文化价值
    uint256 public beta = 50;   // 权重: 效用价值
    uint256 public gamma = 20;  // 权重: 市场价值

    // 模拟 Access Token (FT_k) 的余额 [cite: 49]
    // Mapping: TokenID => User Address => Amount of Access Credits
    mapping(uint256 => mapping(address => uint256)) public accessBalances;

    // 资产动态数据
    struct DynamicData {
        uint256 accessCount;    // U_k: 累计访问频率 [cite: 55]
        uint256 marketValue;    // M_k: 市场热度 (由 Oracle 更新) [cite: 55]
    }
    mapping(uint256 => DynamicData) public assetStats;

    // 事件用于取证 [cite: 61, 62]
    event AccessRightsPurchased(uint256 indexed tokenId, address indexed buyer, uint256 amount, uint256 price);
    event AccessConsumed(uint256 indexed tokenId, address indexed user, string actionType);
    event MarketValueUpdated(uint256 indexed tokenId, uint256 newValue);

    constructor(address _nftAddress) Ownable(msg.sender) {
        nftContract = CulturalAssetNFT(_nftAddress);
    }

    //  Oracle Interface: 更新市场价值 M_k
    function updateMarketValue(uint256 tokenId, uint256 _marketValue) external onlyOwner {
        assetStats[tokenId].marketValue = _marketValue;
        emit MarketValueUpdated(tokenId, _marketValue);
    }

    // [cite: 53] Dynamic Pricing Algorithm: P_k(t) = alpha*C + beta*U + gamma*M
    function calculatePrice(uint256 tokenId) public view returns (uint256) {
        (uint256 C_k, ) = nftContract.getAssetData(tokenId);
        uint256 U_k = assetStats[tokenId].accessCount;
        uint256 M_k = assetStats[tokenId].marketValue;

        // 简单线性公式实现，单位为 wei (实际部署需考虑精度缩放)
        uint256 price = (alpha * C_k) + (beta * U_k) + (gamma * M_k);
        
        // 防止价格为0
        if (price == 0) return 1000 wei;
        return price;
    }

    // [cite: 7, 88] Atomic Exchange: 购买访问权 (FT)
    function buyAccess(uint256 tokenId, uint256 amount) external payable {
        uint256 unitPrice = calculatePrice(tokenId);
        uint256 totalCost = unitPrice * amount;

        require(msg.value >= totalCost, "Insufficient funds sent");

        // 1. 更新 Utility Value (U_k) [cite: 55]
        assetStats[tokenId].accessCount += amount;

        // 2. 发放 Access Token (记账) [cite: 49]
        accessBalances[tokenId][msg.sender] += amount;

        // 3. 版权分发：将资金转给 NFT 持有者 (Ownership Owner) 
        // 实际场景中可能包含平台手续费，此处简化为全额转给版权方
        (, address nftOwner) = nftContract.getAssetData(tokenId);
        payable(nftOwner).transfer(msg.value);

        // [cite: 61] 记录交易以便追踪
        emit AccessRightsPurchased(tokenId, msg.sender, amount, unitPrice);
    }

    // [cite: 37, 65] 消费访问权 (请求解密/查看)
    function consumeAccess(uint256 tokenId) external {
        require(accessBalances[tokenId][msg.sender] >= 1, "No access rights (FT) available");

        // 扣除 1 个单位的访问权
        accessBalances[tokenId][msg.sender] -= 1;

        //  触发事件，模拟释放解密密钥或 URL
        emit AccessConsumed(tokenId, msg.sender, "VIEW_3D_MODEL");
    }
    
    // 系统治理：调整定价参数
    function updatePricingParams(uint256 _alpha, uint256 _beta, uint256 _gamma) external onlyOwner {
        alpha = _alpha;
        beta = _beta;
        gamma = _gamma;
    }
}
