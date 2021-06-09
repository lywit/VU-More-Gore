--Credit to Ensio for his version checking code!
require('__shared/version')

function GetCurrentVersion()
    -- Version Check Code Credit: https://gitlab.com/n4gi0s/vu-mapvote by N4gi0s
    options = HttpOptions({}, 10)
    options.verifyCertificate = false
    res = Net:GetHTTP("https://raw.githubusercontent.com/lywit/VU-More-Gore/main/mod.json", options)

    if res.status ~= 200 then
        return null
    end

    json = json.decode(res.body)
    return json.Version

end

function CheckVersion()

    if GetCurrentVersion() ~= localModVersion then

        print("Version: " .. localModVersion)
        print("More Gore is out of date! Download the latest version here: https://github.com/lywit/VU-More-Gore");
        print('Latest version: ' .. json.Version)

    else

        print("Version: " .. localModVersion)
        

    end

end

CheckVersion()