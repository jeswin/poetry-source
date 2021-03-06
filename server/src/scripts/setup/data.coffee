basho = {
    username: 'basho', 
    name: 'Matsuo Bashō', 
    location: 'Ueno, Iga Province', 
    domainid: 'basho',
    email: 'poets@poe3.com',
    picture: '/images/poets/matsuobasho.jpg',
    thumbnail: '/images/poets/matsuobasho_t.jpg',
}

buson = {
    username: 'buson', 
    name: 'Yosa Buson', 
    location: 'Kema, Settsu', 
    domainid: 'buson',
    email: 'poets@poe3.com',
    picture: '/images/poets/yosabuson.jpg',
    thumbnail: '/images/poets/yosabuson_t.jpg',
}

issa = {
    username: 'issa', 
    name: 'Kobayashi Issa', 
    location: 'Kashiwabara', 
    domainid: 'issa',
    email: 'poets@poe3.com',
    picture: '/images/poets/kobayashiissa.jpg',
    thumbnail: '/images/poets/kobayashiissa_t.jpg',
}

shiki = {
    username: 'shiki', 
    name: 'Masaoka Shiki', 
    location: 'Matsuyama city, Iyo province ', 
    domainid: 'shiki',
    email: 'poets@poe3.com',
    picture: '/images/poets/masaokashiki.jpg',
    thumbnail: '/images/poets/masaokashiki_t.jpg',
}

hemingway = {
    username: 'hemingway', 
    name: 'Ernest Hemingway', 
    location: ' Oak Park, Illinois', 
    domainid: 'hemingway',
    email: 'poets@poe3.com',
    picture: '/images/poets/ernesthemingway.jpg',
    thumbnail: '/images/poets/ernesthemingway_t.jpg',
}

users = [basho, buson, issa, shiki, hemingway]

poems = []
#Bashō's poems
poems.push {
    user: 'basho',
    type: 'haiku',
    attachmentType: 'image',
    attachment: 'http://www.brazahood.com/blog/wp-content/uploads/2010/04/Scarecrow-m.jpg',
    parts: [
        { 
            content: 
                "Scarecrow in the hillock\n
                 Paddy field --\n
                 How unaware!  How useful!"
        }
    ]
}

poems.push {
    user: 'basho',
    type: 'haiku',
    attachmentType: 'image',
    attachment: 'http://www.kensmithart.com/images/RainShelter.jpg',
    attachmentCreditsName: 'Ken Smith',
    attachmentCreditsWebsite:'http://www.kensmithart.com/rain_shelter.htm',    
    parts: [
        {
            content: 
               "Passing through the world\n
                Indeed this is just\n
                Sogi's rain shelter."
        }
    ]
}

poems.push {
    user: 'basho',
    type: 'haiku',
    attachmentType: 'image',
    attachment: 'http://www.womansday.com/cm/womansday/images/WV/05-wd0809-Sado-Island-Japan-2.jpg',
    attachmentCreditsName: 'Paolo Negri',
    attachmentCreditsWebsite:'http://www.womansday.com/life/15-stunning-sunrises-sunsets-84085',
    parts: [
        {
            content: 
               "A wild sea-\n
               In the distance over Sado\n
               The Milky Way." 
        }
    ]
}

poems.push {
    user: 'basho',
    type: 'haiku',
    parts: [
        { 
            content: 
               "Morning and evening\n
                Someone waits at Matsushima!\n
                One-sided love." 
        }
    ]
}

poems.push {
    user: 'basho',
    type: 'haiku',
    parts: [
        { 
            content: 
               "Wrapping dumplings in\n
               bamboo leaves, with one finger\n
               she tidies her hair"
        }
    ]
}

poems.push {
    user: 'basho',
    type: 'haiku',
    attachmentType: 'image',
    attachment: 'http://www.flyvision.org/sbm/bia/pix/bronze/buddha13.jpg',
    parts: [
        { 
            content: 
               "On Buddha's deathday,\n
               wrinkled tough old hands pray –\n
               the prayer beads' sound"
        }
    ]
}

poems.push {
    user: 'basho',
    type: 'haiku',
    parts: [
        { 
            content: 
               "this autumn\n
               why am I aging so?\n
               to the clouds a bird"
        }
    ]
}

poems.push {
    user: 'basho',
    type: 'haiku',
    parts: [
        { 
            content: 
               "a peasant’s child\n
               husking rice, pauses\n
               to look at the moon"
        }
    ]
}        

#Buson's poems
poems.push {
    user: 'buson',
    type: 'haiku',
    attachmentType: 'image',
    attachment: 'http://farm7.staticflickr.com/6120/6278736236_c59ca7099f_b.jpg',
    parts: [
        { 
            content: 
              "light of the moon\n
               moves west - flowers' shadows\n
               creep eastward" 
        }
    ]
}

poems.push {
    user: 'buson',
    type: 'haiku',
    parts: [
        { 
            content:
               "head pillowed on my arm\n
                such affection for myself\n
                and this smoky moon" 
        }
    ]
}

poems.push {
    user: 'buson',
    type: 'haiku',
    attachmentType: 'image',
    attachment: 'http://farm7.staticflickr.com/6008/5961860178_9172cc0eee_b.jpg',
    parts: [
        { 
            content: 
               "a kite floats\n
                at the place in the sky\n
                where it floated yesterday"
        }
    ]
}

poems.push {
    user: 'buson',
    type: 'haiku',
    attachmentType: 'image',
    attachment: 'http://www.chiefrabbi.org/wp-content/uploads/2012/09/rain-v2.jpg',     
    parts: [
        { 
            content: 
                "a long hard journey\n
                rain beating down the clover\n
                like a wanderer's feet"
        }
    ]
}

poems.push {
    user: 'buson',
    type: 'haiku',
    attachmentType: 'image',
    attachment: 'http://4.bp.blogspot.com/-rdR6DcxR774/UHegmoBH_dI/AAAAAAAAA1Q/nvyXGy1Sq2g/s1600/Spring_alley.jpg',    
    parts: [
        { 
            content: 
               "coming back—\n
                so many pathways\n
                through the spring grass"
        }
    ]
}

#Issa's poems
poems.push {
    user: 'issa',
    type: 'haiku',
    parts: [
        { 
            content: "
                Hey! Don’t swat:\n
                the fly wrings his hands\n
                on bended knees." 
        }
    ]
}

poems.push {
    user: 'issa',
    type: 'haiku',
    parts: [
        { 
            content: 
                "Don't kill that poor fly!\n
                He cowers, wringing\n
                his hands for mercy" 
        }
    ]
}

poems.push {
    user: 'issa',
    type: 'haiku',
    parts: [
        { 
            content: 
               "A man, just one --\n
                also a fly, just one --\n
                in the huge drawing room." 
        }
    ]
}

poems.push {
    user: 'issa',
    type: 'haiku',
    parts: [
        { 
            content: 
               "I'm going out,\n
                flies, so relax,\n
                make love." 
        }
    ]
}

poems.push {
    user: 'issa',
    type: 'haiku',
    parts: [
        { 
            content: 
                "The toad! It looks like\n
                it could belch\n
                a cloud." 
        }
    ]
}        
        
#Shiki's poems
poems.push {
    user: 'shiki',
    type: 'haiku',
    attachmentType: 'image',
    attachment: 'http://images.fineartamerica.com/images-medium-large/spider-web-and-cactus-in-black-and-white-anya-brewley-schultheiss.jpg',    
    parts: [
        { 
            content: 
               "After killing\n
                a spider, how lonely I feel\n
                in the cold of night!" 
        }
    ]
}

poems.push {
    user: 'shiki',
    type: 'haiku',
    parts: [
        { 
            content: 
               "A mountain village\n
                under the pilled-up snow\n
                the sound of water." 
        }
    ]
}

poems.push {
    user: 'shiki',
    type: 'haiku',
    parts: [
        { 
            content:
               "Night; and once again,\n
                the while I wait for you, cold wind\n
                turns into rain." 
        }
    ]
}

poems.push {
    user: 'shiki',
    type: 'haiku',
    attachmentType: 'image',
    attachment: 'http://www.old-picture.com/indians/pictures/Indian-Crossing-RiverHorse.jpg',
    parts: [
        { 
            content: 
               "The summer river:\n
                although there is a bridge, my horse\n
                goes through the water." 
        }
    ]
}

poems.push {
    user: 'shiki',
    type: 'haiku',
    parts: [
        { 
            content: 
                "A lightning flash:\n
                between the forest trees\n
                I have seen water." 
        }
    ]
}        
                        
#Hemingway's poems
poems.push {
    user: 'hemingway',
    type: 'free-verse',
    tags: 'war',    
    parts: [
        { 
            content:   
               "Some came in chains\n
                Unrepentant but tired.\n
                Too tired but to stumble.\n
                Thinking and hating were finished\n
                Thinking and fighting were finished.\n
                Cures thus a long campaign,\n 
                Making death easy."
        }
    ]
}                

poems.push {
    user: 'hemingway',
    type: 'free-verse',
    tags: 'war',
    attachmentType: 'image',
    attachment: 'http://3.bp.blogspot.com/_YYMeAu4i7gA/Sw98ZrMbu2I/AAAAAAAAG_c/q3r8PedDrz8/s1600/nazi-germany-second-world-war-ww2-color-clour-pictures-images-photos-hitler-birhday-1939.jpg',
    parts: [
        { 
            content:   
               "Half a million dead wops\n
                And he got a kick out of it\n
                The son of a bitch."
        }
    ]
}                

poems.push {
    user: 'hemingway',
    type: 'free-verse',
    tags: 'war',
    attachmentType: 'image',
    attachment: 'http://24.media.tumblr.com/tumblr_mdo4ku9auN1rubozqo1_1280.jpg',
    parts: [
        { 
            content:   
               "Desire and\n
                All the sweet pulsing aches\n
                And gentle hurtings\n
                That were you,\n
                Are gone into the sullen dark.\n
                Now in the night you come unsmiling\n
                To lie with me\n
                A dull, cold, rigid bayonet\n
                On my hot-swollen, throbbing soul."
        }
    ]
}           

#Collaborative. (Fake)
poems.push {
    user: 'basho',
    type: 'haiku',
    attachmentType: 'image',
    attachment: 'http://farm2.staticflickr.com/1391/5116756173_471354b8b6_b.jpg',    
    parts: [
        { content: "No blossoms and no moon," },
        { content: "and he is drinking sake", user: 'buson' },
        { content: "all alone!", user:'shiki' }
    ],
    notes: "Note: This haiku was entirely written by Basho, and not really a collaborative work."
}        

       

exports.users = users
exports.posts = poems
