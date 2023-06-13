import { io } from "socket.io-client";

import snmp from "net-snmp";

const OIDS = {
    "pdmPowerRequestedState": "1.3.6.1.4.1.2699.1.4.1.4.3.0",
    "pdmTempSensorTemp": "1.3.6.1.4.1.2699.1.4.1.10.1.1.4.1",
    "pdmTempSensorStatus": "1.3.6.1.4.1.2699.1.4.1.10.1.1.3.1",
    "pdmAlertCode": "1.3.6.1.4.1.2699.1.4.1.18.1.1.4.1",
    "pdmGeneralProductName": "1.3.6.1.4.1.2699.1.4.1.2.1.0",
    "pdmGeneralSerialNumber": "1.3.6.1.4.1.2699.1.4.1.2.2.0",
    "pdmDisplaySetInputSource": "1.3.6.1.4.1.2699.1.4.1.6.1.1.3.1",
    "pdmAudioVolume": "1.3.6.1.4.1.2699.1.4.1.16.2.0",
    "pdmAudioMute": "1.3.6.1.4.1.2699.1.4.1.16.3.0",
    "pdmButtonEnabled": "1.3.6.1.4.1.2699.1.4.1.17.1.1.3.1",
}

const STATE = {
    "ON": 11,
    "Standby": 7
}

const session = snmp.createSession("192.168.0.10", "private");

const socket = io("ws://rstring.mgul.ac.ru", {
    query: {
	    room: 446
    }
});

function invertObj(obj) {
    return Object.fromEntries(
        Object.entries(obj).map((entry) => entry.reverse())
    );
}

function getOIDByName(name) {
    return OIDS[name];
}

function getNameByOID(OID) {
    return invertObj(OIDS)[OID];
}

function isVarbindError(e) {
    return snmp.isVarbindError(e);
}

function ObjectType() {
    console.log(snmp.ObjectType.Integer)
    return snmp.ObjectType;
}

const utils = { getNameByOID, getOIDByName, isVarbindError, ObjectType };
export { session, socket, utils };
