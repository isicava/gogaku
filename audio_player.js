nol_com.getFlashVersion=function(){
	var t=[],n=navigator,u=[];
	if(typeof n.plugins!='undefined' && typeof n.plugins['Shockwave Flash']=='object'){
		for(var i=0;i<n.mimeTypes.length;i++){
			if(n.mimeTypes[i].type=='application/x-shockwave-flash'){
				t=n.mimeTypes[i].enabledPlugin.description.match(/\d+/gi);
				if(nol_com.chkVersion(t,u)){
					u=getv(t);
				}
				break;
			}
		}
	}
	else if(typeof window.ActiveXObject!='undefined'){//IE
		for(var i=7;i<30;i++){
			eval("try {var res=new ActiveXObject('ShockwaveFlash.ShockwaveFlash."+i+"')}catch(e){error=e};");
			if(res){
				t=res.GetVariable('$version').match(/\d+/gi);
				u=getv(t);
				break;
			}
		}
	}
	function getv(t){
		var ret=[0,0,0];
		for(var i=0;i<3;i++){
			if(t[i]!=undefined)ret[i]=t[i];
		}
		return ret;
	}
	return getv(u);
};
nol_com.getPlayerDetector=function(){
	var o=nol_com;
	var b=o.browser;
	if(b.iOS){return 'HLS';}
	if(b.AndroidVer>=4){return 'HLS';}
	var ua=navigator.userAgent;
	if(typeof(nol_hlsua)!='undefined'){
		for(var i=0;i<nol_hlsua.length;i++){
			var re=new RegExp(nol_hlsua[i],'i');
			if(ua.search(re)>-1){
				return 'HLS';
			}
		}
	}
	if(o.chkFlashVideo()){return 'Flash';}
	return false;
};
nol_com.chkVersion=function(myver,lmver){
	function initar(ar,def,len){
		for(var i=0;i<len;i++){
			if(typeof ar[i] =='undefined'){
				ar[i]=def;
			}
		}
		return ar;
	}
	myver=initar(myver,0,3);
	lmver=initar(lmver,0,3);
	if(myver[0]>lmver[0]){
		return true;
	}
	else if(myver[0]==lmver[0]){
		if(myver[1]>lmver[1]){
			return true;
		}
		else if(myver[1]==lmver[1]){
			if(myver[2]>=lmver[2]){
				return true;
			}
		}
	}
	return false;
};
var g_playerDetect=nol_com.getPlayerDetector();
$(document).ready(function(){
	setAudioPlayer.display();
});
var setAudioPlayer = {
	url:{
		listxml : connectDirectory+'/listdataflv.xml',
		phrase  : 'phrase.xml',
		akmai   : 'https://nhkmovs-i.akamaihd.net/i/gogaku/',
		akmai_m3u8: '/master.m3u8',
		akamai_streaming: 'streaming/mp4/'+ connectDirectory +'/',
		akamai_phrase: 'phrase/mp4/'
	},
	tgtDiv: {
		phrase: '.phraseplayer'
	},
	swf: {
		streaming     : '../../common/swf/gogaku_streaming.swf',
		streaming_smp : '../../common/swf/gogaku_streaming_smp.swf',
		keyphrase     : '../../common/swf/gogaku_keyphrase.swf'
	},
	//画面表示処理
	display: function(){
		//埋め込み確認
		var embedFlag_streaming = $('#programPlayer').size()? true: false;
		var embedFlag_phrase = $('#contentthisweek div.bg div.phraseplayer').size()? true: false;

		if(g_playerDetect=='HLS'){
			if(embedFlag_streaming){ this.getXML(this.url.listxml  ,setAudioPlayer.ProgramSetHtml); }
			if(embedFlag_phrase){ this.getXML(this.url.phrase ,setAudioPlayer.PhraseSetHtml); }
			$('#programPlayer').remove();
		}
		else if(g_playerDetect=='Flash'){
			if(embedFlag_streaming){ this.ProgramSetFlash('external_flashcontent_program'); }
			if(embedFlag_phrase){ this.PhraseSetFlash('external_flashcontent_keyphrase'); }
			$('#playerSP').remove();
		}
		else{//対象外
			if(embedFlag_streaming){
				var ht = '<div class="inner"><div class="bg"><div>'
					+'<p>お使いの機種では音声を聞くことができません。</p>'
					+'</div></div></div>';
				$('#programPlayer').html(ht);
			}
		}
	},
	getXML   : function(url ,cb){
		$.ajax({
			url:url,
			dataType:'xml',
			//cache:true,
			success:function(xml){
				cb(xml);
			}
		});
	}, 
	ProgramSetHtml  : function(xml){
		/*
			番組を聴く　html5版
		*/
		var html  = '<div class="player"><div class="inner"><div class="bg">';
			html += '<p class="audioSelect">一覧から放送日を選択して下さい。</p><ul class="clearfix">';
		var $items=$(xml).find('music');
		var _path = '';

		for(var i=0;i<$items.length;i++){
			_path = "'"+ setAudioPlayer.makeFilePath( $items.eq(i).attr('file'), setAudioPlayer.url.akamai_streaming ) +"'";
			html+='<li><a href="javascript:void(0);" onclick="setAudioPlayer.setAudioData('+ _path +',this)">'+ $items.eq(i).attr('hdate') +'</a></li>';
		}
		html+='</ul><p class="audioControl">音声が選択されていません。</p>';
		html+='<audio id="programAudio" src="#" controls="true">';
		html+='<p>音声を再生するには、audioタグをサポートしたブラウザが必要です。</p>';
		html+='</audio>';
		html+='</div></div></div>';

		$('#playerSP').html(html);
	},
	PhraseSetHtml  : function(xml){
		/*
			今週のフレーズ　html5版（複数対応）
		*/
		var $items=$(xml).find('music');
		var html;
		var len = $(setAudioPlayer.tgtDiv.phrase).size();
		for (var i=0; i < len; i++){
			html='<audio id="phraseAudio" src="'+ setAudioPlayer.makeFilePath( $items.eq(i).attr('file'), setAudioPlayer.url.akamai_phrase ) +'" controls="true"></audio>';
			$(setAudioPlayer.tgtDiv.phrase).eq(i).html(html);
		}
		if(nol_com.browser.Android){//for Android
			$('iframe.ifPhPlayer').css({'height':"60px"});
		}
	},
	ProgramSetFlash : function(_id){
		/*
			番組を聴く　flash版
		*/
		var program_player  = '<div class="inner"><div class="bg"><div id="'+_id+'">';
			program_player += '<p class="noticeNoflash">音声を聴くには<a href="http://get.adobe.com/jp/flashplayer/?Lang=Japanese" target="_blank" title="NHKサイトを離れます">ADOBE FLASH PLAYER</a>が必要です。</p>';
			program_player += '</div></div></div>';

		$('#programPlayer').html(program_player);

		if(nol_com.browser.Android){//Android用
			swfobject.embedSWF(setAudioPlayer.swf.streaming_smp, _id, "300", "324", "8", false, {dir:connectDirectory}, {allowScriptAccess:"always", wmode:"transparent"});
		}
		else{//PC用
			swfobject.embedSWF(setAudioPlayer.swf.streaming, _id, "680", "205", "8", false, {dir:connectDirectory}, {allowScriptAccess:"always", wmode:"transparent"});
		}
	},
	PhraseSetFlash : function(_id){
		/*
			今週のフレーズ　flash版（複数対応）
		*/

		var id;
		var html;
		var len = $(setAudioPlayer.tgtDiv.phrase).size();
		for (var i=0; i < len; i++){
			id = _id + (i + 1);
			html = '<div id="' + id + '"></div>';
			$(setAudioPlayer.tgtDiv.phrase).eq(i).html(html);
			swfobject.embedSWF(setAudioPlayer.swf.keyphrase, id, "37", "19", "8", false, {fileNum:i}, {allowScriptAcess:"always", wmode:"transparent"});
		}
	},
	XMLerror : function(){
		$('.player').hide();
	},
	setAudioData: function(file, obj){
		var str = $(obj).text() + 'を選択中です。';
		$('p.audioControl').text(str);
		$('#programAudio').attr("src", file);
		
		$('#programAudio').remove();
		$('p.audioControl').after('<audio id="programAudio" src="'+file+'" controls="true"></audio>')

		//自動再生用
		document.getElementById('programAudio').play();

	},
	makeFilePath: function(file, type){
		return setAudioPlayer.url.akmai + type + file + setAudioPlayer.url.akmai_m3u8;
	}
};

