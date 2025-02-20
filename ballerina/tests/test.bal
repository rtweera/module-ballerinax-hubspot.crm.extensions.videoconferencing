// Copyright (c) 2025, WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/lang.runtime;
import ballerina/test;

configurable string hapikey = ?;
configurable int appId = ?;

configurable string liveServerUrl = "https://api.hubapi.com/crm/v3/extensions/videoconferencing/settings";
configurable string localServerUrl = "http://localhost:9090";
configurable boolean isLiveServer = true;

final int:Signed32 appIdSigned32 = <int:Signed32>appId;
final string serviceUrl = isLiveServer ? liveServerUrl : localServerUrl;
final Client hubSpotVideoConferencing = check initClient();

isolated function initClient() returns Client|error {
    if isLiveServer {
        final ApiKeysConfig apiKeysConfig = {
            hapikey: hapikey
        };
        return check new (apiKeysConfig, {}, serviceUrl);
    }
    return check new ({
        hapikey: hapikey
    }, {}, serviceUrl);
}

@test:Config {
    enable: true
}
function testDeleteSettings() returns error? {
    http:Response response = check hubSpotVideoConferencing->/[appIdSigned32].delete();
    test:assertTrue(response.statusCode == 204, "Error deleting settings");
}

@test:Config {
    enable: true,
    dependsOn: [testDeleteSettings]
}
function testGetEmptySettings() returns error? {
    if isLiveServer {
        // Wait for the server to be updated the settings
        runtime:sleep(60);
    }
    ExternalSettings|http:ClientRequestError|error settings = hubSpotVideoConferencing->/[appIdSigned32]();
    test:assertTrue(settings is http:ClientRequestError, "Error getting settings");
}

@test:Config {
    enable: true,
    dependsOn: [testGetEmptySettings]
}
function testPutSettings() returns error? {
    ExternalSettings payload = {
        createMeetingUrl: "https://example.com/create-meeting"
    };
    ExternalSettings settings = check hubSpotVideoConferencing->/[appIdSigned32].put(payload);
    test:assertEquals(settings.createMeetingUrl, "https://example.com/create-meeting", "Error putting settings");
}

@test:Config {
    enable: true,
    dependsOn: [testPutSettings]
}
function testPutIncorrectAppId() returns error? {
    ExternalSettings payload = {
        createMeetingUrl: "https://example.com/create-meeting"
    };
    ExternalSettings|http:ClientRequestError|error settings = hubSpotVideoConferencing->/[1234].put(payload);
    test:assertTrue(settings is http:ClientRequestError, "Error putting settings with incorrect appId");
}

@test:Config {
    enable: true,
    dependsOn: [testPutSettings]
}
function testGetSettings() returns error? {
    if isLiveServer {
        // Wait for the server to be updated the settings
        runtime:sleep(60);
    }
    ExternalSettings|http:Response settings = check hubSpotVideoConferencing->/[appIdSigned32]();
    test:assertTrue(settings is ExternalSettings, "Type mismatch");
    if settings is ExternalSettings {
        test:assertEquals(settings.createMeetingUrl, "https://example.com/create-meeting", "Error getting settings");
    }
}

@test:Config {
    enable: true,
    dependsOn: [testPutSettings]
}
function testGetIncorrectAppId() returns error? {
    ExternalSettings|http:ClientRequestError|error settings = hubSpotVideoConferencing->/[1234]();
    test:assertTrue(settings is http:ClientRequestError, "Error getting settings");
}

@test:Config {
    enable: true,
    dependsOn: [testGetSettings]
}
function testDeleteIncorrectAppId() returns error? {
    http:Response response = check hubSpotVideoConferencing->/[1234].delete();
    test:assertEquals(response.statusCode, 404, "Error deleting settings with incorrect appId");
}

@test:Config {
    enable: true,
    dependsOn: [testPutSettings]
}
function testPutCompeteSettings() returns error? {
    ExternalSettings payload = {
        createMeetingUrl: "https://example.com/create-meeting",
        updateMeetingUrl: "https://example.com/update-meeting",
        deleteMeetingUrl: "https://example.com/delete-meeting",
        userVerifyUrl: "https://example.com/verify-user",
        fetchAccountsUri: "https://example.com/fetch-accounts"
    };
    ExternalSettings settings = check hubSpotVideoConferencing->/[appIdSigned32].put(payload);
    test:assertEquals(settings.createMeetingUrl, "https://example.com/create-meeting", "Error putting complete settings");
    test:assertEquals(settings?.updateMeetingUrl, "https://example.com/update-meeting", "Error putting complete settings");
    test:assertEquals(settings?.deleteMeetingUrl, "https://example.com/delete-meeting", "Error putting complete settings");
    test:assertEquals(settings?.userVerifyUrl, "https://example.com/verify-user", "Error putting complete settings");
    test:assertEquals(settings?.fetchAccountsUri, "https://example.com/fetch-accounts", "Error putting complete settings");
}

@test:Config {
    enable: true,
    dependsOn: [testGetSettings]
}
function testDeleteSettingsAgain() returns error? {
    http:Response response = check hubSpotVideoConferencing->/[appIdSigned32].delete();
    test:assertTrue(response.statusCode == 204, "Error deleting settings");
}

