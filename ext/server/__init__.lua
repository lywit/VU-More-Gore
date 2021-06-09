function Server:GetCurrentVersion()
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

    function Server:CheckVersion()

        if Server:GetCurrentVersion() ~= localModVersion then

            print("Version: " .. localModVersion)
            print("This mod seems to be out of date! Please visit https://github.com/lywit/VU-More-Gore");
            print('Latest version: ' .. json.Version)

        else

            print("Version: " .. localModVersion)
            print("You're running the lastest version!")

        end

    end