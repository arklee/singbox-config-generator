const fs = require('fs');

function convert_1sub_to_obj(str) {
    const obj = {}
    const url = new URL(str);

    const type = url.protocol.split(":")[0]
    if (type === 'trojan') {
        obj.type = type
        obj.password = url.username
        obj.tag = decodeURIComponent(url.hash.slice(1))
        obj.server_port = Number(url.port)
        obj.server = url.hostname
        obj.tls = {
            "enabled": true,
            "insecure": true
        }
    } else if (type === 'ss') {
        const method_and_password = atob(url.username).split(':')
        obj.type = 'shadowsocks'
        obj.method = method_and_password[0]
        obj.password = method_and_password[1]
        obj.tag = decodeURIComponent(url.hash.slice(1))
        obj.server_port = Number(url.port)
        obj.server = url.hostname
        obj.network = 'tcp'
        obj.tcp_fast_open = false
    }
    return obj
}

function create_groups(outbounds) {

    const sub_tag_list = []
    outbounds.forEach(e => {
        sub_tag_list.push(e.tag)
    })

    const out_group = [
            {
                "type": "selector",
                "tag": "select",
                "outbounds": [
                  "url-test",
                ].concat(sub_tag_list),
                "default": "url-test"
              },
              {
                "type": "urltest",
                "tag": "url-test",
                "outbounds": sub_tag_list,
                "url": "https://www.gstatic.com/generate_204",
                "interval": "3m",
                "tolerance": 50
        },
        // {
        //     type: "selector",
        //     tag: "🚀 节点选择",
        //     outbounds: [
        //         "direct",
        //         "♻️ 自动选择"
        //     ].concat(sub_tag_list),
        //     default: "♻️ 自动选择"
        // },
        // {
        //     type: "urltest",
        //     tag: "♻️ 自动选择",
        //     outbounds: sub_tag_list,
        //     url: "http://www.gstatic.com/generate_204",
        //     interval: "5m",
        //     tolerance: 50
        // },
        // {
        //     type: "selector",
        //     tag: "Ⓜ️ 微软服务",
        //     outbounds: [
        //         "🎯 全球直连",
        //         "🚀 节点选择"
        //     ].concat(sub_tag_list),
        //     default: "🚀 节点选择"
        // },
        // {
        //     type: "selector",
        //     tag: "🍎 苹果服务",
        //     outbounds: [
        //         "🎯 全球直连",
        //         "🚀 节点选择"
        //     ].concat(sub_tag_list),
        //     default: "🚀 节点选择"
        // },
        // {
        //     type: "selector",
        //     tag: "GLOBAL",
        //     outbounds: ["direct"].concat(sub_tag_list),
        // },
        // {
        //     type: "selector",
        //     tag: "🎯 全球直连",
        //     outbounds: [
        //         "direct",
        //         "🚀 节点选择",
        //         "♻️ 自动选择"
        //     ]
        // },
        // {
        //     type: "selector",
        //     tag: "🐟 漏网之鱼",
        //     outbounds: [
        //         "🎯 全球直连",
        //         "🚀 节点选择",
        //         "♻️ 自动选择"
        //     ]
        // }
    ]
    return out_group
}

function extract_outbounds_from_singbox(jsonstr) {
    const outbounds = JSON.parse(jsonstr).outbounds
    const filteredOutbounds = outbounds.filter(item => (item.type === 'shadowsocks' || item.type === 'trojan' || item.type === 'hysteria2'));
    return filteredOutbounds
}

function convert_sub_to_outbounds(str, json, other_nodes) {
    const decode_data = atob(str)
    const arr = decode_data.split("\r\n")
    outbounds = []
    arr.forEach(e => {
        if (e !== "") {
            outbounds.push(convert_1sub_to_obj(e))
        }
    });
    outbounds = outbounds.concat(JSON.parse(other_nodes).outbounds)
    outbounds = outbounds.concat(extract_outbounds_from_singbox(json))
    out_group = create_groups(outbounds)
    outbounds = outbounds.concat(out_group)
    return outbounds
}

const args = process.argv.slice(2)

fs.readFile("defaultconfig/other_nodes.json", 'utf8', (err, data1) => {
    if (err) {
        console.error(err);
        return;
    }
    fs.readFile(args[1], 'utf8', (err, data2) => {
        if (err) {
            console.error(err);
            return;
        }
        fs.readFile(args[0], 'utf8', (err, data3) => {
            if (err) {
                console.error(err);
                return;
            }
            const obj = { outbounds: convert_sub_to_outbounds(data3, data2, data1) }
            const jsonString = JSON.stringify(obj, null, 2)
            fs.writeFile(args[2], jsonString, (err) => {
                if (err) {
                    console.error('Error writing file:', err);
                }
            });
        });
    });
});