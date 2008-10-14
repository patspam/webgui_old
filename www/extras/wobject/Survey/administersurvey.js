if (typeof Survey == "undefined") {
    var Survey = {};
}

Survey.Form = new function() {
   
    var multipleChoice = {'Multiple Choice':1,'Gender':1,'Yes/No':1,'True/False':1,'Ideology':1, 'Race':1,'Party':1,'Education':1
            ,'Scale':1,'Agree/Disagree':1,'Oppose/Support':1,'Importance':1,
            'Likelihood':1,'Certainty':1,'Satisfaction':1,'Confidence':1,'Effectiveness':1,'Concern':1,'Risk':1,'Threat':1,'Security':1};
    var text = {'Text':1, 'Email':1, 'Phone Number':1, 'Text Date':1, 'Currency':1};
    var slider = {'Slider':1, 'Dual Slider - Range':1, 'Multi Slider - Allocate':1};
    var dateType = {'Date':1,'Date Range':1};
    var fileUpload = {'File Upload':1};
    var hidden = {'Hidden':1};

    var hasFile;
    var verb = 0; 
    var lastSection = 'first';

    var toValidate;

    var sliderWidth = 500;

    var sliders;
    
//    this.submittimer;


    this.displayQuestions = function(params){
        toValidate = new Array();//clear array
        var qs = params.questions;
        var s = params.section;
        sliders = new Array();

        //What to show and where 
        document.getElementById('survey').innerHTML = params.html; 
//var te = document.createElement('span'); 
//te.innerHTML = "<input type=button id=testB name='Reload Page' value='Reload Page'>";
//document.getElementById('survey').appendChild(te);
//YAHOO.util.Event.addListener("testB", "click", function(){Survey.Comm.callServer('','loadQuestions');});   

        if(qs[0] != undefined){
            if(lastSection != s.id|| s.everyPageTitle > 0){
                document.getElementById('headertitle').style.display='block';
            }
            if(lastSection != s.id|| s.everyPageText > 0){
                document.getElementById('headertext').style.display = 'block';
            }

            if(lastSection != s.id && s.questionsOnSectionPage != '1'){
                var span = document.createElement("div"); 
                span.innerHTML = "<input type=button id='showQuestionsButton' value='Continue'>";
                span.style.display = 'block';
            
                document.getElementById('header').appendChild(span);
                YAHOO.util.Event.addListener("showQuestionsButton", "click", 
                    function(){ 
                        document.getElementById('showQuestionsButton').style.display = 'none';
                        if(s.everyPageTitle == 0){
                            document.getElementById('headertitle').style.display = 'none';
                        }
                        if(s.everyPageText == 0){
                            document.getElementById('headertext').style.display = 'none';
                        }
                        document.getElementById('questions').style.display='inline';
                        Survey.Form.addWidgets(qs);             
                    });   
            }else{
                document.getElementById('questions').style.display='inline';
                Survey.Form.addWidgets(qs);             
            }
            lastSection = s.id;
        }else{
            document.getElementById('headertitle').style.display='block';
            document.getElementById('headertext').style.display = 'block';
            document.getElementById('questions').style.display='inline';
            Survey.Form.addWidgets(qs);             
        }
    }
        //Display questions
    this.addWidgets = function(qs){ 
        hasFile = false;
        for(var i = 0; i < qs.length; i++){
            var q = qs[i];
            var verts = '';
            var verte = '';
            for(var x in q.answers){
                for(var y in q.answers[x]){
                    if(q.answers[x][y] == undefined){q.answers[x][y] = '';}
                }
            }

            //Check if this question should be validated
            if(q.required == 1){
               toValidate[q.id] = new Array();
               toValidate[q.id]['type'] = q.questionType;
               toValidate[q.id]['answers'] = new Array();
            } 
            

            if(multipleChoice[q.questionType]){
                var butts = new Array(); 
                verb = 0; 
                for(var x = 0; x < q.answers.length; x++){
                    var a = q.answers[x];
                    if(toValidate[q.id]){
                        toValidate[q.id]['answers'][a.id] = 1; 
                    }
                    var b = document.getElementById(a.id+'button');
                    /*
                        b = new YAHOO.widget.Button({ type: "checkbox", label: a.answerText, id: a.id+'button', name: a.id+'button',
                        value: a.id, 
                        container: a.id+"container", checked: false });
                    */
//                    b.on("click", this.buttonChanged,[b,a.id,q.maxAnswers,butts,qs.length,a.id]);
//                    YAHOO.util.Event.addListener(a.id+'button', "click", this.buttonChanged,[b,a.id,q.maxAnswers,butts,qs.length,a.id]);
                    if(a.verbatim == 1){
                        verb = 1;
                    }
                    YAHOO.util.Event.addListener(a.id+'button', "click", this.buttonChanged,[b,a.id,q.maxAnswers,butts,qs.length,a.id]);
                    b.hid = a.id;
                    butts.push(b);
                }
            }
            else if(dateType[q.questionType]){
                for(var x = 0; x < q.answers.length; x++){
                    var a = q.answers[x];
                    if(toValidate[q.id]){
                        toValidate[q.id]['answers'][a.id] = 1; 
                    }
                    var calid = a.id+'container';
                    var c = new YAHOO.widget.Calendar(calid,{title:'Choose a date:', close:true});
                    c.selectEvent.subscribe(this.selectCalendar,[c,a.id],true);
                    c.render();
                    c.hide();
                    var b = new YAHOO.widget.Button({  label:"Select Date",  id:"pushbutton"+a.id, container:a.id+'button' });
                    b.on("click", this.showCalendar,[c]);
                }
            }
            else if(slider[q.questionType]){
                //First run through and put up the span placeholders and find the max value for an answer, to know how big the allocation points will be.
                var max = 0;
                if(q.questionType == 'Dual Slider - Range'){
                    new this.dualSliders(q);
                }else{
                    for(var s in q.answers){
                        var a = q.answers[s];
                        YAHOO.util.Event.addListener(a.id, "blur", this.sliderTextSet);   
                        if(a.max - a.min > max){max = a.max - a.min;}
                    }
                }
                if(q.questionType == 'Multi Slider - Allocate'){
                    //sliderManagers[sliderManagers.length] = new this.sliderManager(q,max);
                    for(var x = 0; x < q.answers.length; x++){
                        var a = q.answers[x];
                        if(toValidate[q.id]){
                            toValidate[q.id]['total'] =  a.max; 
                            toValidate[q.id]['answers'][a.id] = 1; 
                        }
                    }
                    new this.sliderManager(q,max);
                }
                else if(q.questionType == 'Slider'){
                    new this.sliders(q); 
                }
            }

            else if(fileUpload[q.questionType]){
                hasFile = true;
            }

            else if(text[q.questionType]){
                var a = q.answers[x];
                if(toValidate[q.id]){
                    toValidate[q.id]['answers'][a.id] = 1; 
                }
            }
        }
        YAHOO.util.Event.addListener("submitbutton", "click", this.formsubmit);   
    }


    this.formsubmit = function(event){
        var submit = 1;//boolean for if all was good or not
        for(var i in toValidate){
            var answered = 0;
            if(toValidate[i]['type'] == 'Multi Slider - Allocate'){
                var total = 0;
                for(var z in toValidate[i]['answers']){
                    total += Math.round(document.getElementById(z).value);
                }
                if(total == toValidate[i]['total']){answered = 1;}
                else{
                    var amountLeft = toValidate[i]['total']-total;
                    alert("Please allocate the remaining "+amountLeft+ ".");
                }
            }else{
                for(var z in toValidate[i]['answers']){
                    var v = document.getElementById(z).value;
                    if(v != '' && v != undefined){
                        answered = 1;
                        break;
                    }
                }
            }
            if(answered == 0){
                submit = 0;
                document.getElementById(i+'required').innerHTML = "<font color=red>*</font>";
            }else{
                document.getElementById(i+'required').innerHTML = "";
            }
        }
        if(submit == 1){
console.log("Submitting");
            Survey.Comm.callServer('','submitQuestions','surveyForm',hasFile);
        }
    }




    this.dualSliders = function(q){
        var total = sliderWidth; 
//        var sliders = new Array();
            var a1 = q.answers[0];
            var a2 = q.answers[1];
            var scale = sliderWidth/a1.max;

            var id = q.id;
            var a1id = a1.id;
            var a2id = a2.id;

            var a1h = document.getElementById(a1id);
            var a2h = document.getElementById(a2id);
            var a1s = document.getElementById(a1id+'show');
            var a2s = document.getElementById(a2id+'show');
            var s = YAHOO.widget.Slider.getHorizDualSlider(id+'slider-bg', 
                a1id+"slider-min-thumb", a2id+"slider-max-thumb", 
                sliderWidth, 1*scale, [1,sliderWidth]);
            sliders[id] = s;
//console.log(1);

            s.minRange = 4; 
            var updateUI = function () { 
               var min = Math.round(s.minVal/scale), 
                   max = Math.round(s.maxVal/scale); 
               a1h.value = min;  
               a1s.innerHTML = min;  
               a2h.value = max;  
               a2s.innerHTML = max;  
           }; 
   
           // Subscribe to the dual thumb slider's change and ready events to 
           // report the state. 
//           s.subscribe('ready', updateUI); 
           //s.subscribe('change', updateUI);  
           s.subscribe('slideEnd', updateUI);  
    }
    this.sliders = function(q){
        var total = sliderWidth; 
        for(var i in q.answers){
            var a = q.answers[i];
            var step = Math.round(q.answers[i].step); 
            var min = Math.round(parseFloat(q.answers[i].min));
            var distance = Math.round(parseFloat(q.answers[i].max) + (-1 * min));
            var scale = Math.round(sliderWidth/distance);
            var lang  = YAHOO.lang;
            var id = a.id;
            var s = YAHOO.widget.Slider.getHorizSlider(id+'slider-bg', id+'slider-thumb', 
                0, sliderWidth, (scale*step));
            s.scale = scale;
            sliders[q.Survey_questionid] = new Array();
            sliders[q.Survey_questionid][id] = s;
            s.input = a.id; 
            s.scale = scale;
            document.getElementById(id).value = a.min;
            var check = function() {
                var t = document.getElementById(this.input);
                t.value = this.getRealValue();
            };
            s.getRealValue = function() {
                return Math.round(parseFloat(( (this.getValue() / total) * distance) + min )); 
            }
            s.subscribe("slideEnd", check);
        }
    }
    //an object which creates sliders for allocation type questions and then manages their events and keeps them from overallocating
    this.sliderManager = function(q,t){
        var total = sliderWidth; 
        var step = Math.round(parseFloat(q.answers[0].step)); 
        var min = Math.round(parseFloat(q.answers[0].min));
        var distance = Math.round(parseFloat(q.answers[0].max) + (-1 * min));
        var scale = Math.round(sliderWidth/distance);
        for(var i in q.answers){
            var a = q.answers[i];
            var Event = YAHOO.util.Event;
            var lang  = YAHOO.lang;
            var id = a.id+'slider-bg';
            var s = YAHOO.widget.Slider.getHorizSlider(id, a.id+'slider-thumb', 
                0, sliderWidth, scale*step);
            s.animate = false;
            if(sliders[q.id] == undefined){
                sliders[q.id] = new Array();
            }
            sliders[q.id][a.id] = s;
            s.input = a.id;
            s.lastValue = 0;
            var check = function() {
                var t = 0;
                for(var x in sliders[q.id]){
                    t+= sliders[q.id][x].getValue();
                }
                if(t > total){
                    t -= this.getValue();
                    t = Math.round(t);
                    this.setValue(total-t);// + (scale*step));
                    document.getElementById(this.input).value = Math.round(parseFloat(( ((total-t) / total) * distance) + min )); 
                }else{ 
                    this.lastValue = this.getValue();
                    document.getElementById(this.input).value = this.getRealValue();
                }
            };
            s.subscribe("change", check);
            s.subscribe("slideEnd", check);
            var manualEntry = function(e){
              // set the value when the 'return' key is detected 
              if (Event.getCharCode(e) === 13 || e.type == 'blur') { 
                  var v = parseFloat(this.value, 10); 
                  v = (lang.isNumber(v)) ? v : 0; 
//                  v *= scale;
                  v = ( ( (v-min) / distance))*total;
                  // convert the real value into a pixel offset 
                  for(var sl in sliders[q.id]){
                    if(sliders[q.id][sl].input == this.id){
                        sliders[q.id][sl].setValue(Math.round(v)); 
                    }
                  }
              } 
            }
            Event.on(document.getElementById(s.input), "blur", manualEntry);
            Event.on(document.getElementById(s.input), "keypress", manualEntry);
            
            s.getRealValue = function() { 
                return Math.round(parseFloat(( (this.getValue() / total) * distance) + min )); 
            }
            document.getElementById(s.input).value = s.getRealValue();
        }
    }

    this.selectCalendar = function(event,args,obj){
        var id = obj[1];
        var selected = args[0]; 
        var date = selected[0];
        var year = date[0], month = date[1], day = date[2];
        var input = document.getElementById(id);
        input.value = month + "/" + day + "/" + year;
        obj[0].hide();
    }


    this.showCalendar = function(event,objs){
        objs[0].show();
    }

    this.sliderTextSet = function(event,objs){
        this.value = this.value * 1;
        if(this.value == 'NaN'){this.value = 0;}
        sliders[this.id].setValue(Math.round(this.value * sliders[this.id].scale)); 
    }

    this.buttonChanged = function(event,objs){
        var b = objs[0];
        var qid = objs[1];
        var maxA = objs[2];
        var butts = objs[3];
        var qsize = objs[4];
        var aid = objs[5];
        max = parseFloat(max);
//        clearTimeout(Survey.Form.submittimer);
        if(maxA == 1){
            if(b.className == 'mcbutton-selected'){
                document.getElementById(b.hid).value = 0;
                b.className='mcbutton';
            }else{
                document.getElementById(b.hid).value = 1;
                b.className='mcbutton-selected';
            }
            for(var i in butts){
                if(butts[i] != b){
                    butts[i].className='mcbutton';
                    document.getElementById(butts[i].hid).value = '';
                }
            }
        } 
        else if(b.className == 'mcbutton'){
            var bscount = 0;//button selected count
            for(var i in butts){
                if(butts[i].className == 'mcbutton-selected'){bscount++;}
            }
            var max = maxA - bscount;//= parseFloat(document.getElementById(qid+'max').innerHTML);
            if(max == 0){
                b.className='mcbutton';
                //warn that options used up
            }
            else{
                b.className='mcbutton-selected';
                //document.getElementById(qid+'max').innerHTML = parseFloat(max-1);
                document.getElementById(b.hid).value = 1;
            }
        }else{
            b.className='mcbutton';
            var bscount = 0;//button selected count
            for(var i in butts){
                if(butts[i].className == 'mcbutton-selected'){bscount++;}
            }
            var max = maxA - bscount;//= parseFloat(document.getElementById(qid+'max').innerHTML);
//            document.getElementById(qid+'max').innerHTML = parseFloat(max+1);
            document.getElementById(b.hid).value = '';
        }
/*
        if(qsize == 1 && b.className == 'mcbutton-selected'){
            if(! document.getElementById(aid+'verbatim')){
                Survey.Form.submittimer=setTimeout("Survey.Form.formsubmit()",500);
            }
        }
*/
    }
}();




//----------------------------------------------------------------
//
//      Initialize survey 
//
//----------------------------------------------------------------
Survey.OnLoad = new function() {
    var e = YAHOO.util.Event;
    this.init = function() {
        e.onDOMReady(this.initHandler);
    }
    this.initHandler = function(){
        Survey.Comm.setUrl('/'+document.getElementById('assetPath').value);
        Survey.Comm.callServer('','loadQuestions');
    }
}();

Survey.OnLoad.init();
