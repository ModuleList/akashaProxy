import { defineConfig } from 'vitepress'

export default defineConfig( {
    ignoreDeadLinks: true,
    locales: {
        root: {
            label: 'English',
            lang: 'en-US',
            title: "AkashaProxy",
            description: "This is AkashaProxy Web Tools",
            themeConfig: {}
        },
        zh: {
            label: '简体中文',
            lang: 'zh-CN',
            title: "虚空代理",
            description: "虚空代理 Web 工具",
            themeConfig: {}
        }
    },
})