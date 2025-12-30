import QtQuick 1.1
import com.nokia.meego 1.0
import QtMultimediaKit 1.1

PageStackWindow {
    id: appWindow
    initialPage: mainPage
    showStatusBar: true
    showToolBar: true
    
    property bool isPlaying: false
    property string nowPlayingName: ""
    
    Component.onCompleted: {
        theme.inverted = true
        console.log("App started, loading channels...")
        sr.loadChannels()
        sr.loadLatestEpisodes()
    }
    
    // Audio Player
    Audio {
        id: audioPlayer
        volume: 1.0
        
        onStatusChanged: {
            console.log("Audio status:", status)
            if (status === Audio.Buffering) {
                statusLabel.text = "Buffrar..."
            } else if (status === Audio.EndOfMedia) {
                statusLabel.text = "Klar"
                isPlaying = false
            } else if (status === Audio.InvalidMedia) {
                statusLabel.text = "Fel"
                isPlaying = false
            }
        }
        
        onStarted: {
            console.log("Audio started")
            isPlaying = true
            statusLabel.text = "Spelar"
        }
        
        onPausedChanged: {
            if (paused) {
                isPlaying = false
                statusLabel.text = "Pausad"
            }
        }
        
        onError: {
            console.log("Audio error:", error, errorString)
            statusLabel.text = "Fel: " + errorString
        }
    }
    
    // Backend connections
    Connections {
        target: sr
        
        onChannelsChanged: {
            console.log("Channels changed")
            try {
                var items = JSON.parse(sr.channelsJson)
                channelsModel.clear()
                // Dummy-Eintrag damit P1 sichtbar wird
                channelsModel.append({id: 0, name: "--- Kanaler ---", dummy: true})
                for (var i = 0; i < items.length; i++) {
                    items[i].dummy = false
                    channelsModel.append(items[i])
                }
            } catch(e) { console.log("channels error:", e) }
        }
        
        onLatestEpisodesChanged: {
            console.log("Latest episodes changed")
            try {
                var items = JSON.parse(sr.latestJson)
                latestModel.clear()
                for (var i = 0; i < items.length; i++) {
                    latestModel.append(items[i])
                }
            } catch(e) { console.log("latest error:", e) }
        }
        
        onCategoriesChanged: {
            try {
                var items = JSON.parse(sr.categoriesJson)
                categoriesModel.clear()
                for (var i = 0; i < items.length; i++) {
                    categoriesModel.append(items[i])
                }
                categoriesBusy.running = false
            } catch(e) { categoriesBusy.running = false }
        }
        
        onProgramsChanged: {
            try {
                var items = JSON.parse(sr.programsJson)
                programsModel.clear()
                for (var i = 0; i < items.length; i++) {
                    programsModel.append(items[i])
                }
                programsBusy.running = false
            } catch(e) { programsBusy.running = false }
        }
        
        onEpisodesChanged: {
            try {
                var items = JSON.parse(sr.episodesJson)
                episodesModel.clear()
                for (var i = 0; i < items.length; i++) {
                    episodesModel.append(items[i])
                }
                episodesBusy.running = false
            } catch(e) { episodesBusy.running = false }
        }
        
        onSearchResultsChanged: {
            try {
                var items = JSON.parse(sr.searchJson)
                searchModel.clear()
                for (var i = 0; i < items.length; i++) {
                    searchModel.append(items[i])
                }
                searchBusy.running = false
            } catch(e) { searchBusy.running = false }
        }
        
        onPlayUrlChanged: {
            console.log("Play URL changed:", sr.playUrl)
            nowPlayingName = sr.playName
            audioPlayer.stop()
            audioPlayer.source = sr.playUrl
            audioPlayer.play()
        }
    }
    
    // Models
    ListModel { id: channelsModel }
    ListModel { id: latestModel }
    ListModel { id: categoriesModel }
    ListModel { id: programsModel }
    ListModel { id: episodesModel }
    ListModel { id: searchModel }
    
    // Main Page
    Page {
        id: mainPage
        orientationLock: PageOrientation.LockPortrait
        
        tools: ToolBarLayout {
            ToolIcon {
                iconId: "toolbar-search"
                onClicked: pageStack.push(searchPage)
            }
            ToolIcon {
                iconId: isPlaying ? "toolbar-mediacontrol-pause" : "toolbar-mediacontrol-play"
                onClicked: {
                    if (isPlaying) {
                        audioPlayer.pause()
                    } else if (audioPlayer.source != "") {
                        audioPlayer.play()
                    }
                }
            }
            ToolIcon {
                iconId: "toolbar-stop"
                onClicked: audioPlayer.stop()
            }
            ToolIcon {
                iconId: "toolbar-view-menu"
                onClicked: mainMenu.open()
            }
        }
        
        Menu {
            id: mainMenu
            MenuLayout {
                MenuItem {
                    text: "Alla kanaler"
                    onClicked: {
                        sr.loadAllChannels()
                        pageStack.push(allChannelsPage)
                    }
                }
                MenuItem {
                    text: "Kategorier"
                    onClicked: {
                        categoriesBusy.running = true
                        sr.loadCategories()
                        pageStack.push(categoriesPage)
                    }
                }
            }
        }
        
        Flickable {
            anchors.fill: parent
            contentHeight: mainColumn.height + 20
            clip: true
            
            Column {
                id: mainColumn
                width: parent.width
                spacing: 6
                
                // Header - kompakt
                Item {
                    width: parent.width
                    height: 36
                    
                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        
                        Label {
                            text: "S'Play"
                            font.pixelSize: 22
                            font.bold: true
                            color: "#00d4aa"
                        }
                        
                        Label {
                            text: "Sveriges Radio"
                            font.pixelSize: 12
                            color: "#888"
                            anchors.bottom: parent.bottom
                        }
                    }
                }
                
                // Now Playing Bar mit Slider (nur wenn etwas spielt)
                Rectangle {
                    visible: nowPlayingName !== ""
                    width: parent.width
                    height: (audioPlayer.seekable && audioPlayer.duration > 0) ? 75 : 45
                    color: "#16213e"
                    
                    Column {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 4
                        
                        Row {
                            width: parent.width
                            spacing: 10
                            
                            Rectangle {
                                width: 32
                                height: 32
                                radius: 16
                                color: isPlaying ? "#00d4aa" : "#666"
                                
                                Label {
                                    anchors.centerIn: parent
                                    text: isPlaying ? "▶" : "❚❚"
                                    font.pixelSize: 12
                                    color: "white"
                                }
                            }
                            
                            Column {
                                width: parent.width - 45
                                
                                Label {
                                    text: nowPlayingName
                                    font.pixelSize: 13
                                    font.bold: true
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                                Label {
                                    id: statusLabel
                                    text: "Redo"
                                    font.pixelSize: 10
                                    color: "#888"
                                }
                            }
                        }
                        
                        // Seek Slider für Podcasts
                        Row {
                            visible: audioPlayer.seekable && audioPlayer.duration > 0
                            width: parent.width
                            spacing: 6
                            
                            Label {
                                text: formatDuration(audioPlayer.position)
                                font.pixelSize: 10
                                color: "#888"
                                width: 35
                            }
                            
                            Slider {
                                id: seekSlider
                                width: parent.width - 85
                                minimumValue: 0
                                maximumValue: audioPlayer.duration
                                value: audioPlayer.position
                                stepSize: 1000
                                
                                onPressedChanged: {
                                    if (!pressed) {
                                        audioPlayer.position = value
                                    }
                                }
                            }
                            
                            Label {
                                text: formatDuration(audioPlayer.duration)
                                font.pixelSize: 10
                                color: "#888"
                                width: 40
                            }
                        }
                    }
                }
                
                // Live Channels
                Item {
                    width: parent.width
                    height: 30
                    
                    Label {
                        text: "Livekanaler"
                        font.pixelSize: 18
                        font.bold: true
                        color: "#00d4aa"
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                
                ListView {
                    id: channelsList
                    width: parent.width
                    height: channelsModel.count * 50
                    clip: true
                    interactive: false
                    
                    model: channelsModel
                    
                    delegate: Rectangle {
                        width: parent.width
                        height: model.dummy ? 30 : 50
                        color: model.dummy ? "transparent" : (index % 2 == 0 ? "#1a1a2e" : "#16213e")
                        
                        Row {
                            anchors.fill: parent
                            anchors.margins: model.dummy ? 4 : 8
                            spacing: 10
                            visible: !model.dummy
                            
                            Rectangle {
                                width: 34
                                height: 34
                                radius: 17
                                color: "#00d4aa"
                                anchors.verticalCenter: parent.verticalCenter
                                
                                Label {
                                    anchors.centerIn: parent
                                    text: model.name ? model.name.charAt(0) : ""
                                    font.pixelSize: 16
                                    font.bold: true
                                    color: "#1a1a2e"
                                }
                            }
                            
                            Label {
                                text: model.name || ""
                                font.pixelSize: 18
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                        
                        // Header für Dummy
                        Label {
                            visible: model.dummy || false
                            text: "Kanaler"
                            font.pixelSize: 18
                            font.bold: true
                            color: "#00d4aa"
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            enabled: !model.dummy
                            onClicked: {
                                console.log("Playing channel:", model.id, model.name)
                                sr.playChannel(model.id)
                            }
                        }
                    }
                }
                
                // Latest Episodes
                Item {
                    width: parent.width
                    height: 30
                    
                    Label {
                        text: "Senast publicerat"
                        font.pixelSize: 18
                        font.bold: true
                        color: "#00d4aa"
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                
                ListView {
                    id: latestList
                    width: parent.width
                    height: Math.min(latestModel.count * 50, 250)
                    clip: true
                    interactive: false
                    
                    model: latestModel
                    
                    delegate: Rectangle {
                        width: parent.width
                        height: 50
                        color: index % 2 == 0 ? "#252525" : "#2a2a2a"
                        
                        Row {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8
                            
                            Rectangle {
                                width: 34
                                height: 34
                                radius: 17
                                color: "#00d4aa"
                                anchors.verticalCenter: parent.verticalCenter
                                
                                Label {
                                    anchors.centerIn: parent
                                    text: "▶"
                                    font.pixelSize: 12
                                    color: "#1a1a2e"
                                }
                            }
                            
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 46
                                spacing: 1
                                
                                Label {
                                    text: model.programName || ""
                                    font.pixelSize: 10
                                    color: "#00d4aa"
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                                
                                Label {
                                    text: model.title || ""
                                    font.pixelSize: 13
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (model.url) {
                                    sr.playEpisodeOrLocal(model.url, model.title, "")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Helper function for duration formatting
    function formatDuration(ms) {
        var secs = Math.floor(ms / 1000)
        var mins = Math.floor(secs / 60)
        secs = secs % 60
        return mins + ":" + (secs < 10 ? "0" : "") + secs
    }
    
    // Search Page
    Page {
        id: searchPage
        orientationLock: PageOrientation.LockPortrait
        
        tools: ToolBarLayout {
            ToolIcon {
                iconId: "toolbar-back"
                onClicked: pageStack.pop()
            }
            ToolIcon {
                iconId: isPlaying ? "toolbar-mediacontrol-pause" : "toolbar-mediacontrol-play"
                onClicked: {
                    if (isPlaying) {
                        audioPlayer.pause()
                    } else if (audioPlayer.source != "") {
                        audioPlayer.play()
                    }
                }
            }
        }
        
        Column {
            anchors.fill: parent
            spacing: 16
            
            TextField {
                id: searchField
                width: parent.width - 20
                anchors.horizontalCenter: parent.horizontalCenter
                placeholderText: "Sök program..."
                
                onTextChanged: {
                    if (text.length >= 2) {
                        searchBusy.running = true
                        sr.search(text)
                    }
                }
            }
            
            BusyIndicator {
                id: searchBusy
                anchors.horizontalCenter: parent.horizontalCenter
                running: false
                visible: running
            }
            
            ListView {
                width: parent.width
                height: parent.height - searchField.height - 50
                clip: true
                model: searchModel
                
                delegate: Rectangle {
                    width: parent.width
                    height: 70
                    color: index % 2 == 0 ? "#1a1a2e" : "#16213e"
                    
                    Row {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12
                        
                        Rectangle {
                            width: 36
                            height: 36
                            radius: 18
                            color: "#00d4aa"
                            anchors.verticalCenter: parent.verticalCenter
                            
                            Label {
                                anchors.centerIn: parent
                                text: "▶"
                                font.pixelSize: 16
                                color: "#1a1a2e"
                            }
                        }
                        
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 60
                            
                            Label {
                                text: model.programName || ""
                                font.pixelSize: 12
                                color: "#00d4aa"
                            }
                            
                            Label {
                                text: model.title || ""
                                font.pixelSize: 16
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (model.url) {
                                sr.playEpisodeOrLocal(model.url, model.title, "")
                            }
                        }
                    }
                }
            }
        }
    }
    
    // All Channels Page
    Page {
        id: allChannelsPage
        orientationLock: PageOrientation.LockPortrait
        
        tools: ToolBarLayout {
            ToolIcon {
                iconId: "toolbar-back"
                onClicked: pageStack.pop()
            }
            ToolIcon {
                iconId: isPlaying ? "toolbar-mediacontrol-pause" : "toolbar-mediacontrol-play"
                onClicked: {
                    if (isPlaying) {
                        audioPlayer.pause()
                    } else if (audioPlayer.source != "") {
                        audioPlayer.play()
                    }
                }
            }
        }
        
        ListView {
            anchors.fill: parent
            model: channelsModel
            clip: true
            
            header: Label {
                text: "Alla kanaler"
                font.pixelSize: 26
                font.bold: true
                height: 60
                verticalAlignment: Text.AlignVCenter
                x: 16
            }
            
            delegate: Rectangle {
                width: parent.width
                height: 60
                color: index % 2 == 0 ? "#1a1a2e" : "#16213e"
                
                Label {
                    text: model.name
                    font.pixelSize: 20
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: sr.playChannel(model.id)
                }
            }
        }
    }
    
    // Categories Page
    Page {
        id: categoriesPage
        orientationLock: PageOrientation.LockPortrait
        
        tools: ToolBarLayout {
            ToolIcon {
                iconId: "toolbar-back"
                onClicked: pageStack.pop()
            }
            ToolIcon {
                iconId: isPlaying ? "toolbar-mediacontrol-pause" : "toolbar-mediacontrol-play"
                onClicked: {
                    if (isPlaying) {
                        audioPlayer.pause()
                    } else if (audioPlayer.source != "") {
                        audioPlayer.play()
                    }
                }
            }
        }
        
        BusyIndicator {
            id: categoriesBusy
            anchors.centerIn: parent
            running: false
            visible: running
            platformStyle: BusyIndicatorStyle { size: "large" }
        }
        
        ListView {
            anchors.fill: parent
            model: categoriesModel
            clip: true
            
            header: Label {
                text: "Kategorier"
                font.pixelSize: 26
                font.bold: true
                height: 60
                verticalAlignment: Text.AlignVCenter
                x: 16
            }
            
            delegate: Rectangle {
                width: parent.width
                height: 55
                color: index % 2 == 0 ? "#1a1a2e" : "#16213e"
                
                Label {
                    text: model.name
                    font.pixelSize: 18
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        programsBusy.running = true
                        sr.loadCategoryPrograms(model.id)
                        pageStack.push(programsPage, {categoryName: model.name})
                    }
                }
            }
        }
    }
    
    // Programs Page
    Page {
        id: programsPage
        orientationLock: PageOrientation.LockPortrait
        property string categoryName: ""
        
        tools: ToolBarLayout {
            ToolIcon {
                iconId: "toolbar-back"
                onClicked: pageStack.pop()
            }
            ToolIcon {
                iconId: isPlaying ? "toolbar-mediacontrol-pause" : "toolbar-mediacontrol-play"
                onClicked: {
                    if (isPlaying) {
                        audioPlayer.pause()
                    } else if (audioPlayer.source != "") {
                        audioPlayer.play()
                    }
                }
            }
        }
        
        BusyIndicator {
            id: programsBusy
            anchors.centerIn: parent
            running: false
            visible: running
            platformStyle: BusyIndicatorStyle { size: "large" }
        }
        
        ListView {
            anchors.fill: parent
            model: programsModel
            clip: true
            
            header: Label {
                text: programsPage.categoryName
                font.pixelSize: 26
                font.bold: true
                height: 60
                verticalAlignment: Text.AlignVCenter
                x: 16
            }
            
            delegate: Rectangle {
                width: parent.width
                height: 65
                color: index % 2 == 0 ? "#1a1a2e" : "#16213e"
                
                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    
                    Label {
                        text: model.name
                        font.pixelSize: 18
                        font.bold: true
                        elide: Text.ElideRight
                        width: parent.width
                    }
                    
                    Label {
                        text: model.description || ""
                        font.pixelSize: 12
                        color: "#888"
                        elide: Text.ElideRight
                        width: parent.width
                    }
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        episodesBusy.running = true
                        sr.loadProgramEpisodes(model.id)
                        pageStack.push(episodesPage, {programName: model.name})
                    }
                }
            }
        }
    }
    
    // Episodes Page
    Page {
        id: episodesPage
        orientationLock: PageOrientation.LockPortrait
        property string programName: ""
        
        tools: ToolBarLayout {
            ToolIcon {
                iconId: "toolbar-back"
                onClicked: pageStack.pop()
            }
            ToolIcon {
                iconId: isPlaying ? "toolbar-mediacontrol-pause" : "toolbar-mediacontrol-play"
                onClicked: {
                    if (isPlaying) {
                        audioPlayer.pause()
                    } else if (audioPlayer.source != "") {
                        audioPlayer.play()
                    }
                }
            }
        }
        
        BusyIndicator {
            id: episodesBusy
            anchors.centerIn: parent
            running: false
            visible: running
            platformStyle: BusyIndicatorStyle { size: "large" }
        }
        
        ListView {
            anchors.fill: parent
            model: episodesModel
            clip: true
            
            header: Label {
                text: episodesPage.programName
                font.pixelSize: 26
                font.bold: true
                height: 60
                verticalAlignment: Text.AlignVCenter
                x: 16
            }
            
            delegate: Rectangle {
                id: episodeDelegate
                width: parent.width
                height: 60
                color: index % 2 == 0 ? "#1a1a2e" : "#16213e"
                
                // Prüfe ob heruntergeladen beim Laden
                property bool downloaded: false
                Component.onCompleted: {
                    if (model.url && model.title) {
                        downloaded = sr.isDownloaded(model.url, model.title)
                    }
                }
                
                // Grüner Balken links wenn heruntergeladen
                Rectangle {
                    width: 4
                    height: parent.height
                    color: "#00d4aa"
                    visible: episodeDelegate.downloaded
                }
                
                Row {
                    anchors.fill: parent
                    anchors.margins: 10
                    anchors.leftMargin: 14
                    spacing: 8
                    
                    // Play Button
                    Rectangle {
                        width: 36
                        height: 36
                        radius: 18
                        color: "#00d4aa"
                        anchors.verticalCenter: parent.verticalCenter
                        
                        Label {
                            anchors.centerIn: parent
                            text: "▶"
                            font.pixelSize: 14
                            color: "#1a1a2e"
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (model.url) {
                                    sr.playEpisodeOrLocal(model.url, model.title, "")
                                }
                            }
                        }
                    }
                    
                    // Title
                    Label {
                        text: model.title || ""
                        font.pixelSize: 14
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 90
                        elide: Text.ElideRight
                    }
                    
                    // Download Button
                    Rectangle {
                        width: 36
                        height: 36
                        radius: 18
                        color: "#2a6"
                        anchors.verticalCenter: parent.verticalCenter
                        
                        Label {
                            anchors.centerIn: parent
                            text: "⬇"
                            font.pixelSize: 16
                            color: "white"
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                console.log("Download clicked:", model.url, model.title)
                                if (model.url) {
                                    downloadSheet.downloadTitle = model.title || "Episode"
                                    downloadSheet.downloadUrl = model.url
                                    sr.downloadEpisode(model.url, model.title || "episode")
                                    downloadSheet.open()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Download Sheet
    Sheet {
        id: downloadSheet
        acceptButtonText: sr.downloadActive ? "" : "Spela"
        rejectButtonText: sr.downloadActive ? "Avbryt" : "Stäng"
        
        property string downloadTitle: ""
        property string downloadUrl: ""
        
        onRejected: {
            if (sr.downloadActive) {
                sr.cancelDownload()
            }
        }
        
        onAccepted: {
            // Spela nedladdad fil
            if (sr.downloadFilePath !== "") {
                sr.playEpisodeOrLocal(downloadUrl, downloadTitle, "")
            }
        }
        
        content: Column {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 20
            
            Label {
                text: "Laddar ner"
                font.pixelSize: 28
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            Label {
                text: downloadSheet.downloadTitle
                font.pixelSize: 16
                width: parent.width
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }
            
            ProgressBar {
                id: downloadProgressBar
                width: parent.width - 40
                anchors.horizontalCenter: parent.horizontalCenter
                value: sr.downloadProgress / 100.0
            }
            
            Label {
                text: sr.downloadProgress + "%"
                font.pixelSize: 18
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            Label {
                visible: !sr.downloadActive && sr.downloadProgress >= 100
                text: "✓ Klar!"
                font.pixelSize: 20
                color: "#00d4aa"
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
    
    // Download finished handler
    Connections {
        target: sr
        onDownloadFinished: {
            console.log("Download finished")
        }
    }
}
