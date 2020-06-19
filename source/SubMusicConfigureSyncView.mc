using Toybox.WatchUi;
using Toybox.Communications;

// This is the View that is used to configure the songs
// to sync. New pages may be pushed as needed to complete
// the configuration.
class SubMusicConfigureSyncView extends WatchUi.View {

	private var d_playlists;
	private var d_menushown = false;
	private var d_api;

    function initialize() {
        View.initialize();
        
        d_api = new SubSonicAPI(method(:onFail));
    }

    // Load your resources here
    function onLayout(dc) {
        // setLayout(Rez.Layouts.ConfigureSyncLayout(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    
    	if (!d_menushown) {
    		System.println("Will send SubSonicRequest now");
    		d_api.getPlaylists(method(:onGetPlaylists));
    		return;
    	}
		d_menushown = false;
		WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }

    // Update the view
    function onUpdate(dc) {
        // Call the parent onUpdate function to redraw the layout
        // View.onUpdate(dc);
        
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);

        // Indicate that the songs are being fetched
        dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, Graphics.FONT_MEDIUM, WatchUi.loadResource(Rez.Strings.fetchingPlaylists), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    
    }

	// handles the response on getplaylists API request
	function onGetPlaylists(playlists) {
		d_playlists = playlists;
		pushSyncMenu();
		WatchUi.requestUpdate();
	}
	
	// creates the sync menu with the playlists from the server
	function pushSyncMenu() {
        var precheckedItems = {};
        
        // precheck local playlists
        var playlists = Application.Storage.getValue(Storage.PLAYLIST_LOCAL);
        if (playlists == null) {
        	playlists = {};
       	}
       	
       	var keys = playlists.keys();
       	for (var idx = 0; idx < keys.size(); ++idx) {
       		var id = keys[idx];
       		precheckedItems[id] = true;
       	}
       	
       	// precheck to be synced playlists
       	var sync_ids = Application.Storage.getValue(Storage.PLAYLIST_SYNC);
        if (sync_ids == null) {
        	sync_ids = {};
        }
        
        keys = sync_ids.keys();
       	for (var idx = 0; idx < keys.size(); ++idx) {
       		var id = keys[idx];
       		precheckedItems[id] = true;
       	}

        // Create the menu, prechecking anything that is to be or has been synced
		var menu = new WatchUi.CheckboxMenu({:title => Rez.Strings.syncMenuTitle});
        for (var idx = 0; idx < d_playlists.size(); ++idx) {
            var item = new WatchUi.CheckboxMenuItem(d_playlists[idx]["name"],
                                                    d_playlists[idx]["songCount"].toString() + " songs",
                                                    d_playlists[idx],
                                                    precheckedItems.hasKey(d_playlists[idx]["id"]),
                                                    {});
            menu.addItem(item);
        }
        WatchUi.pushView(menu, new SubMusicConfigureSyncDelegate(), WatchUi.SLIDE_IMMEDIATE);
        d_menushown = true;
    }
    
    function onFail(responseCode, data) {
    	var title = "Error: " + responseCode;
    	var detail = d_api.respCodeToString(responseCode) + "\n";
    	if (data != null) {
    		detail += data["errorMessage"];
    	}
		WatchUi.switchToView(new ErrorView(title, detail), null, WatchUi.SLIDE_IMMEDIATE);
		d_menushown = true;
		WatchUi.requestUpdate();
	}

}
