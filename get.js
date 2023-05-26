var snmp = require("net-snmp");

const OIDS = {
    "pdmPowerRequestedState": "1.3.6.1.4.1.2699.1.4.1.4.3.0",
    "pdmTempSensorTemp": "1.3.6.1.4.1.2699.1.4.1.10.1.1.4.1",
}

const STATE = {
    "ON": 11,
    "Standby": 7
}

var session = snmp.createSession("192.168.0.10", "private");

const express = require('express')
const app = express()

app.get('/snmp/:name', function(req, res) {
    session.get([OIDS[req.params.name]], function(error, varbinds) {
    if (error) {
        console.error(error);
    } else {
        for (var i = 0; i < varbinds.length; i++) {
            if (snmp.isVarbindError(varbinds[i])) {
                console.error(snmp.varbindError(varbinds[i]));
            } else {
                console.log(varbinds[i].oid + " = " + varbinds[i].value);
                return res.send(varbinds[i].oid + " = " + varbinds[i].value)
            }
        }
    }
    return res.send("error")
});
})

app.get('/snmp/:name/:val', function(req, res) {
var varbinds = [{
    oid: OIDS[req.params.name],
    type: snmp.ObjectType.Integer,
    value: STATE[req.params.val]
}];

session.set(varbinds, function(error, varbinds) {
    if (error) {
        console.error(error.toString());
    } else {
        for (var i = 0; i < varbinds.length; i++) {
            // for version 1 we can assume all OIDs were successful
            console.log(varbinds[i].oid + "|" + varbinds[i].value);
            return res.send(varbinds[i].oid + "|" + varbinds[i].value)
        }
    }
   return res.send("error")
});
})

app.listen(3000)







