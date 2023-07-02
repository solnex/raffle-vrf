# 彩票合约

## 关于 
以fundry框架编写的随机数彩票合约


## 实现了什么功能
1. 用户可以支付一定费用购买彩票
 - 合约会在一段时间后自动摇奖
 - 奖池中的奖金支付给获奖者

## 使用的接口
 - chainlink的随机数功能-VRF
 - chainlink的自动触发功能-需要支付一定油费-Automation

## VRF
verifiable Random Fuctions 是chainlink公司提供的一个服务，可以提供链外的一些随机的的信息，用于实现一些链上的不可预料功能，比如游戏中的攻击概率胜负，抽奖机制等等
### 流程
1. 去官网订阅，连接钱包，会分配一个订阅号 https://vrf.chain.link/
2. 向订阅账户提供link
3. 添加消费合约,也就是使用随机数的合约地址

### 消费合约开发规范
- 继承VRFConsumerBaseV2

``` forge install smartcontractkit/chainlink-brownie-contracts@0.6.1 --no-commit```

- 实现请求随机数的逻辑
- 实现回调函数fulfillRandomWords的逻辑

## Automation

### 流程
1. 订阅Automation
2. chainlink不断检查合约中的checkUpkeep方法，如果条件通过则调用performUpkeep方法

## Devops
- 将模拟前端订阅及fund过程，在本地测试网实现自动化功能
