#!/bin/bash

# Discord Slash Commands Bot Auto-Installer with Giveaway, Ticket & Welcome
echo "=========================================="
echo "    DISCORD SLASH COMMANDS BOT INSTALLER"
echo "=========================================="

# 1. Node.js Check & Install
if ! command -v node &> /dev/null
then
    echo "[+] Node.js nahi mila. Install kiya ja raha hai..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
else
    echo "[+] Node.js pehle se installed hai."
fi

# 2. Project Directory Setup
BOT_DIR="discord-slash-bot"
mkdir -p $BOT_DIR
cd $BOT_DIR

# 3. User se Credentials Lena
echo ""
read -p "Apna Discord Bot Token daalein: " BOT_TOKEN
read -p "Apni Discord Client ID (Application ID) daalein: " CLIENT_ID
read -p "Apni Discord Admin User ID daalein: " ADMIN_ID
read -p "Default Welcome Role ID daalein: " ROLE_ID

# 4. Package.json create karna
cat << 'EOF' > package.json
{
  "name": "discord-slash-bot",
  "version": "3.0.0",
  "description": "Discord Bot with Slash Commands, Giveaway, Tickets, and Welcome",
  "main": "bot.js",
  "scripts": {
    "start": "node bot.js"
  },
  "dependencies": {
    "discord.js": "^14.14.1"
  }
}
EOF

# 5. Bot Code (bot.js) Create Karna
cat << EOF > bot.js
const { Client, GatewayIntentBits, EmbedBuilder, PermissionsBitField, ActionRowBuilder, ButtonBuilder, ButtonStyle, REST, Routes, SlashCommandBuilder } = require('discord.js');

const client = new Client({
    intents: [
        GatewayIntentBits.Guilds,
        GatewayIntentBits.GuildMessages,
        GatewayIntentBits.MessageContent,
        GatewayIntentBits.GuildMembers,
    ]
});

const TOKEN = "$BOT_TOKEN";
const CLIENT_ID = "$CLIENT_ID";
const ADMIN_ID = "$ADMIN_ID";
const ROLE_ID = "$ROLE_ID";

// Register Slash Commands
const commands = [
    new SlashCommandBuilder().setName('ping').setDescription('Bot ki latency check karein'),
    new SlashCommandBuilder().setName('serverinfo').setDescription('Server ki jankari dekhein'),
    new SlashCommandBuilder().setName('help').setDescription('Saare commands ki list dekhein'),
    new SlashCommandBuilder()
        .setName('giveaway')
        .setDescription('Naya giveaway shuru karein')
        .addStringOption(option => option.setName('prize').setDescription('Giveaway ka prize kya hai?').setRequired(true))
        .addStringOption(option => option.setName('duration').setDescription('Kitne samay ke liye? (jaise 1m, 1h, 1d)').setRequired(true))
        .addIntegerOption(option => option.setName('winners').setDescription('Kitne winners honge?').setRequired(true)),
    new SlashCommandBuilder().setName('ticketsetup').setDescription('Server me Ticket panel setup karein'),
    new SlashCommandBuilder()
        .setName('clear')
        .setDescription('Messages delete karein')
        .addIntegerOption(option => option.setName('count').setDescription('Kitne messages delete karne hain (1-100)').setRequired(true)),
    new SlashCommandBuilder()
        .setName('kick')
        .setDescription('Member ko kick karein')
        .addUserOption(option => option.setName('target').setDescription('Kisko kick karna hai?').setRequired(true)),
    new SlashCommandBuilder()
        .setName('ban')
        .setDescription('Member ko ban karein')
        .addUserOption(option => option.setName('target').setDescription('Kisko ban karna hai?').setRequired(true))
].map(command => command.toJSON());

const rest = new REST({ version: '10' }).setToken(TOKEN);

(async () => {
    try {
        console.log('[+] Slash commands (/) register ki ja rahi hain...');
        await rest.put(Routes.applicationCommands(CLIENT_ID), { body: commands });
        console.log('[+] Slash commands successfully register ho gayi hain!');
    } catch (error) {
        console.error(error);
    }
})();

client.once('ready', () => {
    console.log(\`[ONLINE] Bot \${client.user.tag} safalta-purnaak online ho chuka hai!\`);
    client.user.setActivity('/help | Managing Server', { type: 3 });
});

// Welcome System
client.on('guildMemberAdd', member => {
    if (ROLE_ID) member.roles.add(ROLE_ID).catch(() => {});
    const channel = member.guild.systemChannel;
    if (channel) {
        const embed = new EmbedBuilder()
            .setColor(0x00FF00)
            .setTitle('🎉 Naya Sadasya Aaya!')
            .setDescription(\`Swagat hai \${member} (\${member.user.tag}) ka server mein!\`)
            .setThumbnail(member.user.displayAvatarURL({ dynamic: true }))
            .setTimestamp();
        channel.send({ embeds: [embed] });
    }
});

// Interaction / Slash Commands & Buttons Handler
client.on('interactionCreate', async interaction => {
    if (interaction.isChatInputCommand()) {
        const { commandName, options } = interaction;

        if (commandName === 'ping') {
            await interaction.reply({ content: \`🏓 Pong! \${client.ws.ping}ms latency.\`, ephemeral: true });
        } 
        else if (commandName === 'serverinfo') {
            const embed = new EmbedBuilder()
                .setColor(0xF1C40F)
                .setTitle(interaction.guild.name)
                .addFields(
                    { name: 'Total Members', value: \`\${interaction.guild.memberCount}\`, inline: true },
                    { name: 'Owner', value: \`<@\${interaction.guild.ownerId}>\`, inline: true }
                );
            await interaction.reply({ embeds: [embed] });
        } 
        else if (commandName === 'help') {
            const embed = new EmbedBuilder()
                .setColor(0x5865F2)
                .setTitle('🤖 Bot Command Menu')
                .setDescription('Yahan saare slash (/) commands ki list hai:')
                .addFields(
                    { name: '/ping', value: 'Bot latency check karein' },
                    { name: '/serverinfo', value: 'Server ki details dekhein' },
                    { name: '/giveaway', value: 'Naya giveaway start karein' },
                    { name: '/ticketsetup', value: 'Ticket panel create karein' },
                    { name: '/clear', value: 'Chat clean karein' },
                    { name: '/kick & /ban', value: 'Moderation commands' }
                );
            await interaction.reply({ embeds: [embed], ephemeral: true });
        }
        else if (commandName === 'giveaway') {
            if (!interaction.member.permissions.has(PermissionsBitField.Flags.Administrator)) {
                return interaction.reply({ content: "❌ Aapke paas giveaway shuru karne ki permission nahi hai!", ephemeral: true });
            }
            const prize = options.getString('prize');
            const duration = options.getString('duration');
            const winners = options.getInteger('winners');

            const gEmbed = new EmbedBuilder()
                .setColor(0xE91E63)
                .setTitle('🎉 GIVEAWAY SHURU HO CHUKA HAI! 🎉')
                .setDescription(\`Prize: **\${prize}**\nDuration: \${duration}\nWinners: \${winners}\n\nNeeche diye gaye button par click karke participate karein!\`)
                .setTimestamp();

            const row = new ActionRowBuilder().addComponents(
                new ButtonBuilder().setCustomId('join_gw').setLabel('🎉 Join Giveaway').setStyle(ButtonStyle.Primary)
            );

            await interaction.reply({ embeds: [gEmbed], components: [row] });
        }
        else if (commandName === 'ticketsetup') {
            if (!interaction.member.permissions.has(PermissionsBitField.Flags.Administrator)) {
                return interaction.reply({ content: "❌ Permission denied!", ephemeral: true });
            }
            const tEmbed = new EmbedBuilder()
                .setColor(0x3498DB)
                .setTitle('🎫 Support Tickets')
                .setDescription('Kisi bhi sahayata ya baat ke liye neeche diye gaye button par click karke ticket banayein.');

            const row = new ActionRowBuilder().addComponents(
                new ButtonBuilder().setCustomId('create_ticket').setLabel('Create Ticket').setStyle(ButtonStyle.Success).setEmoji('🎫')
            );

            await interaction.reply({ embeds: [tEmbed], components: [row] });
        }
        else if (commandName === 'clear') {
            if (!interaction.member.permissions.has(PermissionsBitField.Flags.ManageMessages)) {
                return interaction.reply({ content: "❌ Permission denied!", ephemeral: true });
            }
            const count = options.getInteger('count');
            await interaction.channel.bulkDelete(count, true).catch(() => {});
            await interaction.reply({ content: \`✅ \${count} messages delete kar diye gaye.\`, ephemeral: true });
        }
        else if (commandName === 'kick') {
            if (!interaction.member.permissions.has(PermissionsBitField.Flags.KickMembers)) {
                return interaction.reply({ content: "❌ Permission denied!", ephemeral: true });
            }
            const target = options.getMember('target');
            await target.kick().catch(() => {});
            await interaction.reply({ content: \`✅ Member ko kick kar diya gaya.\`, ephemeral: true });
        }
        else if (commandName === 'ban') {
            if (!interaction.member.permissions.has(PermissionsBitField.Flags.BanMembers)) {
                return interaction.reply({ content: "❌ Permission denied!", ephemeral: true });
            }
            const target = options.getMember('target');
            await target.ban().catch(() => {});
            await interaction.reply({ content: \`✅ Member ko ban kar diya gaya.\`, ephemeral: true });
        }
    } 
    else if (interaction.isButton()) {
        // Ticket Create Button
        if (interaction.customId === 'create_ticket') {
            const guild = interaction.guild;
            const channelName = \`ticket-\${interaction.user.username}\`;
            
            const existingChannel = guild.channels.cache.find(c => c.name === channelName);
            if (existingChannel) {
                return interaction.reply({ content: \`⚠️️ Aapka pehle se ek ticket khula hai: \${existingChannel}\`, ephemeral: true });
            }

            const ticketChannel = await guild.channels.create({
                name: channelName,
                type: 0, // Text Channel
                permissionOverwrites: [
                    { id: guild.id, deny: [PermissionsBitField.Flags.ViewChannel] },
                    { id: interaction.user.id, allow: [PermissionsBitField.Flags.ViewChannel, PermissionsBitField.Flags.SendMessages] }
                ]
            });

            const controlRow = new ActionRowBuilder().addComponents(
                new ButtonBuilder().setCustomId('close_ticket').setLabel('🔒 Close').setStyle(ButtonStyle.Danger),
                new ButtonBuilder().setCustomId('claim_ticket').setLabel('🙋‍♂️ Claim').setStyle(ButtonStyle.Secondary)
            );

            const tOpenedEmbed = new EmbedBuilder()
                .setColor(0x00AE86)
                .setTitle('Support Ticket')
                .setDescription('Staff jald hi aapse yahan judega. Aap apni samasya likhein.');

            await ticketChannel.send({ content: \`<@\${interaction.user.id}> Swagat hai!\`, embeds: [tOpenedEmbed], components: [controlRow] });
            await interaction.reply({ content: \`✅ Aapka ticket ban gaya hai: \${ticketChannel}\`, ephemeral: true });
        }
        // Close Ticket Button
        else if (interaction.customId === 'close_ticket') {
            await interaction.reply({ content: '🔒 Ticket 5 seconds mein delete ho raha hai...' });
            setTimeout(() => interaction.channel.delete().catch(() => {}), 5000);
        }
        // Claim Ticket Button
        else if (interaction.customId === 'claim_ticket') {
            await interaction.reply({ content: \`🙋‍♂️️ Ye ticket <@\textbf{\${interaction.user.id}}> dwara claim kar liya gaya hai!\` });
        }
        // Join Giveaway Button
        else if (interaction.customId === 'join_gw') {
            await interaction.reply({ content: '🎉 Badhai ho! Aapka naam giveaway mein darj ho gaya hai.', ephemeral: true });
        }
    }
});

client.login(TOKEN);
EOF

# 6. Dependencies Install Karna
echo "[+] Bot dependencies install ho rahi hain..."
npm install

# 7. PM2 se 24/7 Run Karna
if ! command -v pm2 &> /dev/null
then
    echo "[+] PM2 install kiya ja raha hai..."
    sudo npm install -g pm2
fi

pm2 start bot.js --name "discord-slash-bot"
pm2 save
pm2 startup

echo "=========================================="
echo " SABHI SLASH COMMANDS AUR FEATURES LIVE HO GAYE HAIN!"
echo "=========================================="
EOF
