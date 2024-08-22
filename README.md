# Storage Node Setup Guide | StorX Network

**Run or Upgrade a Farmer/Storage Node on StorX Network**

This guide will instruct you how to set up or upgrade Farmer/Storage Node on the StorX Network

**Preliminaries**
- Running a Storage Node on a live network is a responsible job. The credibility of the complete network depends upon the performance of Farmer/Storage Nodes.
- If there are any issues the possibility of your node getting slashed.
- To compensate for the efforts, running a community memes are rewarded with SRX Tokens, knowing that you contribute to the security of a decentralized network while growing your stash.

If you need help, please reach out on the [Community Page](https://storx.tech/support.html). The community members are there to help answer questions and provide tips from experience.

------

**How many SRX (StorX Native Tokens) do I need?**

To qualify for Farmer/Storage Node on StorX Network, you need between **6000 - 1 Million SRX,** with the existential deposit, plus **XDC for transaction fees.**

**Note: The minimum staking amount will be updated as per the new incremental model from 03/08/2021 onwards. [Refer](https://medium.com/storx-network/storx-farm-node-minimum-staking-increment-model-to-avoid-srx-token-inflation-7a343cf89401)**

-----

We requests Storage Node operators to maintain Good Node Reputation to ensure StorX Ecosystem works perfectly.

**Tips for maintaining a Good Node Reputation:**
- Ensure Strong Cloud Infrastructure.
- Higher SRX Stake adds value to “Good” Node Reputation.
- Ensure 100% uptime.
- Always ensure nodes maintain the latest software patch and OS updates.


**Warning:**

- Underperformance can lead to disqualification of nodes, which can lead to No ‘hosting and staking rewards’. Repeated low reputation can lead to a penalty; Staked SRX might be burned as a penalty as it may harm StorX Storage Network.
- Any SRX that you stake for Farmer/Storage Node on StorX Network is liable to be slashed, meaning that an insecure or improper setup may result in loss of reputation leading to slashing of Farmer/Storage Node on StorX Network.

-----

## Initial Set-up

**Requirements**

The most common way for a beginner to run a validator is on a cloud server running Linux. You may choose whatever VPS provider that you prefer, and whatever operating system you are comfortable with. For this guide we will be using Ubuntu 20.04 64-bit or higher, but the instructions should be similar for other platforms.

The storage operations in Farmer/Storage Node on StorX were benchmarked on standard hardware. It is recommended that you run at least the standard hardware in order to ensure they are able to process all storage requirements. The following are not minimum requirements but if you decide to run with less than this beware that you might have performance issues.

- Six Processor Core
- RAM 8 GB (16 GB Recommended)
- Minimum HDD 1 TB SSD / NVME Recommended
- Minimum 10 TB of available bandwidth a month
- Minimum upload speed of 25 MBPS
- Minimum download speed of 25 MBPS
- Ensure Node availability 24/7

**Note: The Node requirements keep changing as the Network evolves.**

**Key Management**

- Private keys are the central primitive of any cryptographic system and need to be handled with extreme care.
- Loss of your private key can lead to irreversible loss of value.

---

# How to Setup StorX Farmer node

**Method 1:- Setup StorX Farmer node Bootstrap Script**

Bootstrap Command StorX Node Setup :-
```
    sudo bash clone_repo.sh
    cd Storage-Node

    sudo bash bootstrap.sh
```

Once identity file process is started in background you need to wait for some hours and then again run bootstrap file

```
    sudo bash bootstrap.sh
```

------

**Step 2: Start your Node**

**For MainNet**
Run:
```
    ./start-node.sh
```

To stop the node or if you encounter any issues use::

```
    TODO
```
---------------------------------

**Step 3: Stake SRX token**

After setting up FarmNode/StorageNode please Stake SRX token from the URL : https://farmer.storx.io/

IMP Note : You have to stake SRX token to get hosting and staking rewards.

## How to Check Status
To check status of your node you can visit your node dashboard anytime by visiting the URL : http://<your-node-ip>:14002

## How to Upgrade your StorX Farmer Node
How to upgrade your StorX node with the latest changes?

```
    git pull
    sudo bash ./upgrade.sh
```

## Troubleshooting


Public discussions on the technical issues, post articles and request for Enhancements and Technical Contributions.

- [Telegram](https://t.me/StorXNetwork) - Stay updated with all the Announcements.
- [Discord](https://discord.gg/ha4Jufj2Nm) - Join the community to find answers to all your questions.
- [Reddit](https://www.reddit.com/r/StorXNetwork) - Join the channel to have a healthy interaction with the community.
- [GitHub](https://github.com/StorXNetwork) - Join the developers community on GitHub
