# elcaro oracle

_Note: Work in progress. Everything may change._

The elcaro oracle is a generic decentralised oracle that can be used to trigger arbitrary off-chain script functions that may call on-chain contract methods.

## What?

See _"How?"_.

## How?

A `script` will be uploaded to ipfs where it's execution can be triggered from a smart-contract by referring to it via it's ipfs content-identifier (CID). A network of nodes will listening to `elcaro` specific events. After executing the defined script its result may be used to call specific contracts methods.

_The following code-snippets should be considered as pseudo-code._

### Script

```python
// script.py

import requests

def printme(str):
   "This prints a passed string into this function"
   print str
   return

def location(location):
    # api-endpoint
    URL = "http://maps.googleapis.com/maps/api/geocode/json"

    # defining a params dict for the parameters to be sent to the API
    PARAMS = {'address':location}

    # sending get request and saving the response as response object
    r = requests.get(url = URL, params = PARAMS)

    # extracting data in json format
    data = r.json()

    # extracting latitude, longitude and formatted address
    # of the first matching location
    latitude = data['results'][0]['geometry']['location']['lat']
    longitude = data['results'][0]['geometry']['location']['lng']
    formatted_address = data['results'][0]['formatted_address']

    # printing the output
    print("Latitude:%s\nLongitude:%s\nFormatted Address:%s" %(latitude, longitude,formatted_address))

    return (latitude, longitude)
```

The shown python script will be uploaded to ipfs.

```bash
➜ ipfs add script.py
added QmZrPf6xunDiwsdbPS33oxiPQoTeztmP6KkWfFPjBjdWH7 script
 967 B / 967 B [===============================================================] 100.00%
```

### Example Contract

```solidity
// LocationContract.sol

import "./elcaro-oracle.sol";

contract LocationContract {
    uint256 longitude;
    uint256 latitude;

    event onLocation(uint256 longitude, uint256 latitude, string stdout, string stderr);

    function locationCallback(uint256 longitude, uint256 latitude, string memory stdout, string memory stderr) public {
        longitude = _longitude;
        latitude = _latitude;
        emit onLocation(longitude, latitude, stdout, stderr);
    }

    function query(string memory query) public {
        Elcaro.call(
            "QmZrPf6xunDiwsdbPS33oxiPQoTeztmP6KkWfFPjBjdWH7", // script-hash
            "location(string)",                               // function
            query,                                            // input parameters
            address(this), "updateLocation(uint256,uint256)"  // output-callback
            true,                                             // stdout
            false                                             // stderr
        );
    }

    function q0() public {
        query("medellin");
    }

    function q1() public {
        query("berlin");
    }
}
```

The contract  `LocationContract` is creating an `elcaro` oracle request event by defining `script-hash`, `function`, `input-parameters`, `output-callback`, `stdin` and `stdout`. Here `script-hash` is the ipfs content-identifier (CID) of the script. It defines what `function` should be called, with what `input-parameters`. If the called function return data, the `output-callback` define what smart-contract method `updateLocation(uint256, uint256)` should be called on what address `address(this)`.

If a node executes such request event, it will at first download the script that is referred to the content-identifier. It will execute the script function with the parameters supplied by the smart-contract. It will save `stdout` and `stderr` during the execution. It will extract the result of the defined call and will finally callback into the defined smart-contract that created the initial request (`outputContract` was set to `address(this)` during the request creation), and will call the defined function `updateLocation(uint256,uint256)`.

Let's imagine that someone is calling function `q0()` of that contract. Here the method `query(string)` with parameter `medellin` will be  called. A node will retrieve the request event, it will execute the script function `location(string)` with the parameter defined within the smart-contract `medellin`. After executing `location("medellin")` the function will return a tuple containing the position, `longitude` and `latitude`, of the medellin.

The node will create a transaction that will send the result to the defined smart-contract. The request defined that the result of request should be send back to the contract that created the original request `address(this)` by calling its method `updateLocation(uint256,uint256)`. The node will now extract the result from the executed function and will create a transaction that encodes the result tuple into a transaction calling `address(this).updateLocation(result[0], result[1])`, where `result` refers to the result of function `location("medellin")`.

If you look at the function `locationCallback(uint256 longitude, uint256 latitude, string memory stdout, string memory stderr)` you notice that additionally to the original function parameters, two additional parameters `stdout` and `stderr` are defined. As already described, during the execution of the script function, `stdout` and `stderr` will be stored and finally uploaded to ipfs. The content-identifiers of `stdout` and `stderr` may be defined by the callback. This behaviour may simplify debugging and can be optionally enabled for each request, see `stdout` and `stderr` boolean parameters of the function call `Elcaro.call(..)`. In the example contract we only define that `stdout` should be stored. If the callback gets executed, the `stdout` content-identifier (CID) of that request will be defined, where `stderr` will be empty. The standard output of the script execution can be easily inspected by executing `ipfs cat <stdout-cid>`.

### `elcaro` node

A node is the component responsible for executing specific requests by executing the defined script function with the corresponding parameters, where its result can be used to call the defined method of a corresponding contract.

Each node's identity is defined by a private-key from where the public-key and the node's account address is derived. The node need to be registered at the `elcaro` contract. The registration should only be possible if a minimum value was supplied. Here `tx.origin` will be used to identify the node. The account address of the node will be added to the nodes data structure. If a node does not behave correctly, it may get punished by reducing the supplied value. Calling `unregister` will remove the peer from the nodes data structure and send the `sent-value - punishment` back to the node account.

Before starting such node, some value need to be transferred to the specified account address. The provided balance will be used to interact with the defined smart-contracts.

#### Node management

Nodes are managed by a data structure that allows to add and remove node account addresses corresponding to the nodes. This data structure should allow to query a node account address that is most near to a specific `uint256`. 

In the example contract, we used `Elcaro.call(..)` to create a request event. Such request event and related members may be defined like:

```solidity
contract Elcaro {
    struct Request {
        string cid;
        string function;
        string input;
        address outputContract;
        string outputMethod;
        bool stdout;
        bool stderr;
        uint block;
    }
    mapping (uint256 => Request) requests;
    event requestEvent(uint256 node_account, uint256 request_hash);
    ...
}
```

Calling `Elcaro.call(..)` will create a new request event. At first a new `Request` instance need to be created by setting the structure members. Here `cid`, `function`, `input`, `outputContract`, `outputMethod`, `stdout`, `stderr` will be set to the corresponding `Elcaro.call(..)` parameters. Where `block` will be set to `block.number`. 

Now the `request_hash` need to be calculated. It is defined as the `keccak256` of the corresponding `Request` instance, taking all defined members into account. This may need to get optimised.

After calculating the `request_hash` a node need to be defined that will be responsible for executing the request. This is done by using the `nodes` data structure. The data structure should allow an efficient lookup of a `node_account` of registered nodes that have a minimal distance to the supplied `request_hash`.

All registered nodes are actively listening to the request events of the specified `elcaro` contract. If a request event was fired, where `node_account` is equal to the node's account, the node will at first retrieve the full request parameters by using the `requests` mapping. Then the node will download the specified script from ipfs using the `cid`. The script function gets executed and the result will be used to call the `outputMethod` of the contract `outputContract`. Additionally to the result `stdout` and `stderr` ipfs content-identifiers may be set in `outputContract` pointing to `stdout` and/or `stderr` that was uploaded to ipfs. `stdout` and `stderr` where produced during the script execution.

If redundant execution is needed, the smart-contract will create multiple request events. Each of them will specify a different `node_account`. Let's say the script need to be executed by `3` different nodes, the contract will search for the `3` nodes that have the minimal distance to the supplied `request_hash`. For each of the found nodes a unique request event is created.

For each execution the responsible node should receive an execution compensation. 

It is possible that a direct call to the defined smart-contract is not wanted, because not everyone should be able to just call the function defined in the request. To restrict calls into smart-contracts a function/modifier can be used by the user to check whether `tx.origin` is matching with the `node_account` of the request. With such mechanism only the node that was "elected" is able to fully execute the corresponding contract method.

### `elcaro` Smart Contract

#### `elcaro` Interface

## Random Notes

### Data structure for node management

- https://github.com/rob-Hitchens/OrderStatisticsTree looks promising
	- could probably get more simplified for our use-case?

### Chainlink

- https://medium.com/@chainlinkgod/scaling-chainlink-in-2020-371ce24b4f31

    - "Currently, it costs about 2,374,048 gas (\$41.71) to request a price update from a network of 21 oracle nodes"

    - "Currently, the cost from all 21 nodes responding with data back on-chain is 1,358,377 gas (\$23.87), with an average cost of 64,684 gas per node (\$1.14)."
