/*global Survey, YAHOO */
if (typeof Survey === "undefined") {
    var Survey = {};
}

(function(){
	
	var INVALID_QUESTION_CLASS = 'survey-invalid'; // CSS class for questions that fail input validation
	var INVALID_SUBMIT_CLASS = 'survey-submit-invalid'; // CSS class for submit div when questions don't validate
	var INVALID_QUESTION_MARKER = 'survey-invalid-marker'; // For default '*' invalid field marker
	
    // All specially-handled question types are listed here
    // (anything else is assumed to be a multi-choice bundle)
    var TEXT_TYPES = {
        'Text': 1,
        'Email': 1,
        'Phone Number': 1,
        'Text Date': 1,
        'Currency': 1,
	    'TextArea': 1
    };
    var NUMBER_TYPES = {
        'Number':1
    };
    var SLIDER_TYPES = {
        'Slider': 1,
        'Dual Slider - Range': 1,
        'Multi Slider - Allocate': 1
    };
    var DATE_SHORT = {
        'Year Month': 1
    };
    var DATE_TYPES = {
        'Date': 1,
        'Date Range': 1
    };
    var UPLOAD_TYPES = {
        'File Upload': 1
    };
    var HIDDEN_TYPES = {
        'Hidden': 1
    };
    
    var hasFile;
    var verb = 0;
    var lastSection = 'first';
    
    var toValidate;
    var sliderWidth = 500;
    var sliders;
    
    function formsubmit(event){
        var submit = 1;//boolean for if all was good or not
        var lowestInvalidY = 0;
        for (var i in toValidate) {
            if (YAHOO.lang.hasOwnProperty(toValidate, i)) {
                var answered = 0;
                if (toValidate[i].type === 'Multi Slider - Allocate') {
                    var total = 0;
                    for (var z in toValidate[i].answers) {
                        if (YAHOO.lang.hasOwnProperty(toValidate[i].answers, z)) {
                            total += Math.round(document.getElementById(z).value);
                        }
                    }
                    if (total === toValidate[i].total) {
                        answered = 1;
                    }
                    else {
                        var amountLeft = toValidate[i].total - total;
                        alert("Please allocate the remaining " + amountLeft + ".");
                    }
                }
                else if (toValidate[i].type === 'Number') {
                    answered = 1;
                    for (var z1 in toValidate[i].answers) {
                        var m = parseFloat(document.getElementById(z1).value);
                        var ansValues = toValidate[i].answers[z1];
                        if((ansValues.max != '' && m > ansValues.max) ||
                           (ansValues.min != '' && m < ansValues.min) ||
                           (ansValues.step != '' && ( (m % ansValues.step) != 0) )){
                            answered = 0;
                            break;
                        }
                    }

                }
                else if (toValidate[i].type === 'Year Month') {
                    answered = 1;//set to true, then let a single failure set it back to false.
                    for (var z1 in toValidate[i].answers) {
                        var m = document.getElementById(z1+'-month').value;
                        var y = document.getElementById(z1+'-year').value;
                        if(m == ''){ answered = 0; }
                        var yInt = parseInt(y, 10);
                        if(!yInt) { answered = 0; }
                        if(yInt < 1000 || yInt > 3000) { answered = 0; }
                        if(answered == 1){ document.getElementById(z1).value = m + "-" + y; }
                    }
                }
                else {
                    for (var z1 in toValidate[i].answers) {
                        if (YAHOO.lang.hasOwnProperty(toValidate[i].answers, z1)) {
                            var v = document.getElementById(z1).value;
                            if (YAHOO.lang.isValue(v) && v !== '') {
                                answered = 1;
                                break;
                            }
                        }
                    }
                }
				var node = document.getElementById(i + 'required');

				var q_parent_node = YAHOO.util.Dom.getAncestorByClassName(node, 'question');
                if (!answered) {
                    submit = 0;
					
					// Apply INVALID_QUESTION_CLASS to the parent question div for people who want to skin Survey
                    YAHOO.util.Dom.addClass(q_parent_node, INVALID_QUESTION_CLASS);
					
					// Insert default '*' marker (can be hidden via CSS for those who want something different)
					node.innerHTML = "<span class='" + INVALID_QUESTION_MARKER + "'>*</span>";
                    
                    // Keep track of the lowest y-coord invalid question (to scroll to)
                    var qY = YAHOO.util.Dom.getY(q_parent_node);
                    lowestInvalidY = lowestInvalidY && lowestInvalidY < qY ? lowestInvalidY : qY;
                }
                else {
                    YAHOO.util.Dom.removeClass(q_parent_node, INVALID_QUESTION_CLASS);
					node.innerHTML = '';
                }
            }
        }
        var submitButton = document.getElementById('submitbutton');
        var submitDiv = submitButton && YAHOO.util.Dom.getAncestorByTagName(submitButton, 'div');
        
        if (submit) {
            submitDiv && YAHOO.util.Dom.removeClass(submitDiv, INVALID_SUBMIT_CLASS);
            YAHOO.log("Submitting");
            Survey.Comm.callServer('', 'submitQuestions', 'surveyForm', hasFile);
        }
        else {
            submitDiv && YAHOO.util.Dom.addClass(submitDiv, INVALID_SUBMIT_CLASS);
            
            // Scroll page to the y-coord of the lowest invalid question
            lowestInvalidY && scrollPage(lowestInvalidY, 1.5, YAHOO.util.Easing.easeOut);
        }
    }
    
    function goBack(event){
        YAHOO.log("Going back");
        Survey.Comm.callServer('', 'goBack');
    }
    
    function scrollPage(to, dur, ease) {
        var setAttr = function(a, v, u) {
            window.scroll(0, v);
        };
    
        var anim = new YAHOO.util.Anim(null,
            { 'scroll' : {
                from : YAHOO.util.Dom.getDocumentScrollTop(),
                to : to }
            },
            dur, ease
        );
        anim.setAttribute = setAttr;
        anim.animate();
    }

    
    function numberHandler(event, objs){
        
        var keycode = event.keyCode;
        var value = this.value;
        
        //if starting a negative number, don't do anything
        if(value == '' || value == "-"){return;}

        var step = objs.step ? objs.step : 1;

        if(!value){this.value = objs.min ? objs.min : 0;} 
        if(value % step > 0){
            this.value = +value + value % step;
        }
            
        if(objs.min != '' && +value < +objs.min){
            this.value = objs.min;
        }

        else if(objs.max != '' && +value > objs.max){this.value = objs.max;}
        else if(+keycode == 40){//key down
            if(objs.min == ''){
                this.value = value - step;
            }
            else if((value - step) >= +objs.min){
                this.value = value - step;
            }  
        }else if(+keycode == 38){//key up
            if(objs.max == ''){
                this.value = +value + +step;
            }
            if(+value + +step <= +objs.max){
                this.value = +value + +step;
            }
        }
    }
    
    function sliderManager(q){
        //total number of pixels in the slider.
        var total = sliderWidth;

        //steps must be integers
        var step = Math.round(parseFloat(q.answers[0].step));

        //the starting value for the left side of the slider
        var min = Math.round(parseFloat(q.answers[0].min));

        //The number of values in between the max and min values
        var distance = parseInt(parseFloat(q.answers[0].max) + (-1 * min));
       
        //Number of pixels each bug step takes
        var bugSteps = parseInt(total / ((+q.answers[0].max + (-1 * q.answers[0].min) ) / step));

        //redefine number of pixels to round number of steps
        total = distance * bugSteps / step;

        var scale = Math.round(total / distance);
        
        //max is just the max value, used for determining allocation sliders. 
        var max = 0;         
        var type = 'slider';

        //find the maximum difference between an answers max and min
        for (var s in q.answers) {
            if (YAHOO.lang.hasOwnProperty(q.answers, s)) {
                var a1 = q.answers[s];
                YAHOO.util.Event.addListener(a1.id, "blur", sliderTextSet);
                if (a1.max - a1.min > max) {
                    max = a1.max - a1.min;
                }
            }
        }

        //Only validate allocation types which must allocate all their points
        if (q.questionType === 'Multi Slider - Allocate') {
            type = 'multi';
            for (var x1 = 0; x1 < q.answers.length; x1++) {
                if (toValidate[q.id]) {
                    toValidate[q.id].total = q.answers[x1].max;
                    toValidate[q.id].answers[q.answers[x1].id] = 1;
                }
            }
        }
        for (var i in q.answers) {
            if (YAHOO.lang.hasOwnProperty(q.answers, i)) {
                var a = q.answers[i];
                var Event = YAHOO.util.Event;
                var lang = YAHOO.lang;
                var id = a.id + 'slider-bg';
                var s = YAHOO.widget.Slider.getHorizSlider(id, a.id + 'slider-thumb', 0, total, scale * step);
                s.animate = true;
                if (YAHOO.lang.isUndefined(sliders[q.id])) {
                    sliders[q.id] = [];
                }
                sliders[q.id][a.id] = s;
                s.input = a.id;
                s.lastValue = 0;
                var check = function(){
                    var t = 0;
                    for (var x in sliders[q.id]) {
                        if (YAHOO.lang.hasOwnProperty(sliders[q.id], x)) {
                            t += sliders[q.id][x].getRealValue();
                        }
                    }
                    if (t > max && type === 'multi') {
                        t -= +this.getRealValue();
                        var newVal = (max-t);
                        this.setValue(newVal*bugSteps/step);
                        //document.getElementById(this.input).value = Math.round(parseFloat((((total - t) / total) * distance) + min));
                        document.getElementById(this.input).value = newVal;
                    }
                    else {
                        this.lastValue = this.getValue();
                        document.getElementById(this.input).value = this.getRealValue();
                    }
                };
                s.subscribe("change", check);
                var manualEntry = function(e){
                    // set the value when the 'return' key is detected 
                    if (Event.getCharCode(e) === 13 || e.type === 'blur') {
                        var v = parseFloat(this.value, 10);
                        v = (lang.isNumber(v)) ? v : 0;
                        //                  v *= scale;
                        v = (((v - min) / distance)) * total;
                        // convert the real value into a pixel offset 
                        for (var sl in sliders[q.id]) {
                            if (sliders[q.id][sl].input === this.id) {
                                sliders[q.id][sl].setValue(Math.round(v));
                            }
                        }
                    }
                };
                Event.on(document.getElementById(s.input), "blur", manualEntry);
                Event.on(document.getElementById(s.input), "keypress", manualEntry);
                var getRealValue = function(){ 
                    return parseInt((this.getValue() / bugSteps * step) + +min);
                };
                s.getRealValue = getRealValue;
                document.getElementById(s.input).value = s.getRealValue();
            }
        }

    }

    function sliderTextSet(event, objs){
        this.value = this.value * 1;
		this.value = YAHOO.lang.isValue(this.value) ? this.value : 0;
    }
    
    function handleDualSliders(q){
        var a1 = q.answers[0];
        var a2 = q.answers[1];
        var scale = sliderWidth / a1.max;
        
        var id = q.id;
        var a1id = a1.id;
        var a2id = a2.id;
        
        var a1h = document.getElementById(a1id);
        var a2h = document.getElementById(a2id);
        var a1s = document.getElementById(a1id + 'show');
        var a2s = document.getElementById(a2id + 'show');
        var s = YAHOO.widget.Slider.getHorizDualSlider(id + 'slider-bg', a1id + "slider-min-thumb", a2id + "slider-max-thumb", sliderWidth, 1 * scale, [1, sliderWidth]);
        sliders[id] = s;
        
        s.minRange = 4;
        var updateUI = function(){
            var min = Math.round(s.minVal / scale), max = Math.round(s.maxVal / scale);
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
    
    function showCalendar(event, objs){
        objs[0].show();
    }
    
    function selectCalendar(event, args, obj){
        var id = obj[1];
        var selected = args[0];
        var date = selected[0];
        var year = date[0], month = date[1], day = date[2];
        var input = document.getElementById(id);
        input.value = month + "/" + day + "/" + year;
        obj[0].hide();
    }
    
    function buttonChanged(event, objs){
        var b = objs[0];
        var qid = objs[1];
        var maxA = objs[2];
        var butts = objs[3];
        var qsize = objs[4];
        var aid = objs[5];
        //max = parseFloat(max);
        //        clearTimeout(Survey.Form.submittimer);
        if (maxA) {
            if (b.className === 'mcbutton-selected') {
                document.getElementById(b.hid).value = 0;
                b.className = 'mcbutton';
            }
            else {
                document.getElementById(b.hid).value = 1;
                b.className = 'mcbutton-selected';
            }
            for (var i in butts) {
                if (YAHOO.lang.hasOwnProperty(butts, i)) {
                    if (butts[i] !== b) {
                        butts[i].className = 'mcbutton';
                        document.getElementById(butts[i].hid).value = '';
                    }
                }
            }
        }
        else 
            if (b.className === 'mcbutton') {
                var bscount = 0;//button selected count
                for (var ib in butts) {
                    if (butts[ib].className === 'mcbutton-selected') {
                        bscount++;
                    }
                }
                var max = maxA - bscount;//= parseFloat(document.getElementById(qid+'max').innerHTML);
                if (max === 0) {
                    b.className = 'mcbutton';
                //warn that options used up
                }
                else {
                    b.className = 'mcbutton-selected';
                    //document.getElementById(qid+'max').innerHTML = parseFloat(max-1);
                    document.getElementById(b.hid).value = 1;
                }
            }
            else {
                b.className = 'mcbutton';
                var bscount1 = 0;//button selected count
                for (var ibb in butts) {
                    if (butts[ibb].className === 'mcbutton-selected') {
                        bscount1++;
                    }
                }
                //var max = maxA - bscount1;//= parseFloat(document.getElementById(qid+'max').innerHTML);
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

    YAHOO.widget.Chart.SWFURL = "/extras/yui/build/charts/assets/charts.swf"; 
    // Public API
    Survey.Summary = {
        globalSummaryDataTip: function(item, index, series){
                    var toolTipText =  "hello";
                    //var toolTipText = series.displayName + " for " + item.section;
                    //toolTipText += "\n" + item[series.yField];
                    return toolTipText;
        },
        showSummary: function(summary,html){
            var html = html;
            document.getElementById('survey').innerHTML = html;


            //Add totoal summary pie chart
            totalSummary =
            [
                { correct: "Correct", count: summary.totalCorrect },
                { correct: "Incorrect", count: summary.totalIncorrect }
            ]

            var totalSummaryDS = new YAHOO.util.DataSource( totalSummary );
            totalSummaryDS.responseType = YAHOO.util.DataSource.TYPE_JSARRAY;
            totalSummaryDS.responseSchema = { fields: [ "correct", "count" ] };

            new YAHOO.widget.PieChart( "chart", totalSummaryDS,
            {
                dataField: "count",
                categoryField: "correct",
                style:
                {
                    padding: 10,
                    legend:
                    {
                        display: "left",
                        padding: 10,
                        spacing: 2,
                        font:
                        {
                            family: "Arial",
                            size: 13
                        }
                    }
                },
                //only needed for flash player express install
                expressInstall: "/extras/yui/build/charts/assets/charts.swf" 
            });

            //define section datatable columns
            var myColumnDefs = [ 
                {key:"Question ID", sortable:true, resizeable:true}, 
                {key:"Question Text", formatter: YAHOO.widget.DataTable.formatText, sortable:true, resizeable:true}, 
                {key:"Answer ID", sortable:true, resizeable:true}, 
                {key:"Correct", sortable:true, resizeable:true}, 
                {key:"Answer Text", formatter: YAHOO.widget.DataTable.formatText, sortable:true, resizeable:true},
                {key:"Score", sortable:true, resizeable:true}, 
                {key:"Value", formatter: YAHOO.widget.DataTable.formatText, sortable:true, resizeable:true} 
            ];
            var sectionSummary = [];
            //Load up datatables and create section data for bar chart
            for(var i = 0; i < summary.sections.length; i++){
                var temp = summary.sections[i];
                sectionSummary[sectionSummary.length] = {"Total Responses": temp.total, "Correct": temp.correct, "Incorrect": temp.inCorrect, "section": (i+1)};
                var myDataSource = new YAHOO.util.DataSource(summary.sections[i].responses);
//These needs to be put in a destroy call list for when the html dom is recreated, if summaries are going to be uses with page reloads, else memory leak.
                myDataSource.responseType = YAHOO.util.DataSource.TYPE_JSARRAY;
                myDataSource.responseSchema = { 
                   fields: ["Question ID","Question Text","Answer ID","Correct","Answer Text","Score","Value"] 
                };
                var tempText = "section"+ (i+1) + "datatable";
                new YAHOO.widget.DataTable(tempText, myColumnDefs, myDataSource, {caption:"Section "+(i+1)});
            }

            //Now create section summary bar charts
            var sectionSummaryDS = new YAHOO.util.DataSource( sectionSummary ); 
            sectionSummaryDS.responseType = YAHOO.util.DataSource.TYPE_JSARRAY; 
            sectionSummaryDS.responseSchema = 
            { 
                fields: [ "Total Responses", "Correct", "Incorrect", "section" ] 
            };
            var sectionSummarySeriesDef =
                [
                    {
                        displayName: "Total Responses",
                        yField: "Total Responses",
                        style:{size:10}
                    },
                    {
                        displayName: "Correct",
                        yField: "Correct",
                        style:{size:10}
                    },
                    {
                        displayName: "Incorrect",
                        yField: "Incorrect",
                        style:{size:10}
                    }
                ];
            //create a Numeric Axis for displaying dollars
            var responseAxis = new YAHOO.widget.NumericAxis();
            responseAxis.title = "Responses";
            //create Category Axis to specify a title for the months
            var sectionAxis = new YAHOO.widget.CategoryAxis();
            sectionAxis.title = "Sections";
            //create the Chart
            var mychart = new YAHOO.widget.ColumnChart( "summarychart", sectionSummaryDS,
            {
                series: sectionSummarySeriesDef,
                xField: "section",
                xAxis: sectionAxis,
                yAxis: responseAxis,
//                dataTipFunction: Survey.Form.globalSummaryDataTip,      //try again in 2.7
                expressInstall: "/extras/yui/build/charts/assets/charts.swf" 
            });

            YAHOO.util.Event.addListener("submitbutton", "click", function(){ Survey.Comm.submitSummary(); });
        }
    };

    Survey.Form = {
        displayQuestions: function(params){
            toValidate = [];
            var qs = params.questions;
            var s = params.section;
            sliders = [];
            
            //What to show and where 
            document.getElementById('survey').innerHTML = params.html;
            //var te = document.createElement('span'); 
            //te.innerHTML = "<input type=button id=testB name='Reload Page' value='Reload Page'>";
            //document.getElementById('survey').appendChild(te);
            //YAHOO.util.Event.addListener("testB", "click", function(){Survey.Comm.callServer('','loadQuestions');});   
            
            if (qs[0]) {
                if (lastSection !== s.id || s.everyPageTitle === '1') {
                    document.getElementById('headertitle').style.display = 'block';
                }
                if (lastSection !== s.id || s.everyPageText === '1') {
                    document.getElementById('headertext').style.display = 'block';
                }
                if (lastSection !== s.id && s.questionsOnSectionPage !== '1') {
                    var span = document.createElement("div");
                    span.innerHTML = "<input type=button id='showQuestionsButton' value='Continue'>";
                    span.style.display = 'block';
                    
                    document.getElementById('survey-header').appendChild(span);
                    
                    YAHOO.util.Event.addListener("showQuestionsButton", "click", function(){
                        document.getElementById('showQuestionsButton').style.display = 'none';
                        if (s.everyPageTitle !== '1') {
                            document.getElementById('headertitle').style.display = 'none';
                        }
                        if (s.everyPageText !== '1') {
                            document.getElementById('headertext').style.display = 'none';
                        }
                        document.getElementById('questions').style.display = 'inline';
                        Survey.Form.addWidgets(qs);
                    });
                }
                else {
                    document.getElementById('questions').style.display = 'inline';
                    Survey.Form.addWidgets(qs);
                }
                lastSection = s.id;
            }
            else {
                document.getElementById('headertitle').style.display = 'block';
                document.getElementById('headertext').style.display = 'block';
                document.getElementById('questions').style.display = 'inline';
                Survey.Form.addWidgets(qs);
            }
        },

        addWidgets: function(qs){
            hasFile = false;
            for (var i = 0; i < qs.length; i++) {
                var q = qs[i];
                if (!q || !q.answers) {
                    // gracefully handle q with no answers
                    continue;
                }
                
                var verts = '';
                for (var x in q.answers) {
                    if (YAHOO.lang.hasOwnProperty(q.answers, x)) {
                        for (var y in q.answers[x]) {
                            if (YAHOO.lang.hasOwnProperty(q.answers[x], y)) {
                                if (YAHOO.lang.isUndefined(q.answers[x][y])) {
                                    q.answers[x][y] = '';
                                }
                            }
                        }
                    }
                }
                
                //Check if this question should be validated.
                //Sliders can't really be not answered, so requiring them makes little sense.
                if (q.required == true && q.questionType != 'Slider') {
                    toValidate[q.id] = [];
                    toValidate[q.id].type = q.questionType;
                    toValidate[q.id].answers = [];
                }
               
                if (DATE_SHORT[q.questionType]) {
                    for (var k = 0; k < q.answers.length; k++) {
                        var ans = q.answers[k];
                        if (toValidate[q.id]) {
                            toValidate[q.id].type = q.questionType;
                            toValidate[q.id].answers[ans.id] = 1;
                        }
                    }
                    continue;
                } 
                
                if (DATE_TYPES[q.questionType]) {
                    for (var k = 0; k < q.answers.length; k++) {
                        var ans = q.answers[k];
                        if (toValidate[q.id]) {
                            toValidate[q.id].answers[ans.id] = 1;
                        }
                        var calid = ans.id + 'container';
                        var c = new YAHOO.widget.Calendar(calid, {
                            title: 'Choose a date:',
                            close: true
                        });
                        c.selectEvent.subscribe(selectCalendar, [c, ans.id], true);
                        c.render();
                        c.hide();
                        var btn = new YAHOO.widget.Button({
                            label: "Select Date",
                            id: "pushbutton" + ans.id,
                            container: ans.id + 'button'
                        });
                        btn.on("click", showCalendar, [c]);
                    }
                    continue;
                }
                
                if (SLIDER_TYPES[q.questionType]) {
                    //First run through and put up the span placeholders and find the max value for an answer, to know how big the allocation points will be.
                    var max = 0;
                    if (q.questionType === 'Dual Slider - Range') {
                        handleDualSliders(q);
                    }
                    else {
                        sliderManager(q);
                    }
                    continue;
                }
                
                if (UPLOAD_TYPES[q.questionType]) {
                    hasFile = true;
                    continue;
                }
                
                if (TEXT_TYPES[q.questionType]) {
                    if (toValidate[q.id]) {
                        toValidate[q.id].answers[q.answers[x].id] = 1;
                    }
                    continue;
                }
                if (NUMBER_TYPES[q.questionType]) {
                    for (var x in q.answers) {
                        if (toValidate[q.id]) {
                            toValidate[q.id].answers[q.answers[x].id] = {'min':q.answers[x].min,'max':q.answers[x].max,'step':q.answers[x].step};
                        }
                        YAHOO.util.Event.addListener(q.answers[x].id, "keyup", numberHandler, q.answers[x]);
                    }
                    continue;
                }
                // Must be a multi-choice bundle
                var butts = [];
                verb = 0;
                for (var j = 0; j < q.answers.length; j++) {
                    var a = q.answers[j];
                    if (toValidate[q.id]) {
                        toValidate[q.id].answers[a.id] = 1;
                    }
                    var b = document.getElementById(a.id + 'button');
                    /*
         b = new YAHOO.widget.Button({ type: "checkbox", label: a.answerText, id: a.id+'button', name: a.id+'button',
         value: a.id,
         container: a.id+"container", checked: false });
         */
                    //                    b.on("click", buttonChanged,[b,a.id,q.maxAnswers,butts,qs.length,a.id]);
                    //                    YAHOO.util.Event.addListener(a.id+'button', "click", buttonChanged,[b,a.id,q.maxAnswers,butts,qs.length,a.id]);
                    if (a.verbatim) {
                        verb = 1;
                    }
                    YAHOO.util.Event.addListener(a.id + 'button', "click", buttonChanged, [b, a.id, q.maxAnswers, butts, qs.length, a.id]);
                    b.hid = a.id;
                    butts.push(b);
                }
            }
            YAHOO.util.Event.addListener("backbutton", "click", goBack);
            YAHOO.util.Event.addListener("submitbutton", "click", formsubmit);
        }
    };
    
    
})();

YAHOO.util.Event.onDOMReady(function(){
    // Survey.Comm.setUrl('/' + document.getElementById('assetPath').value);
    Survey.Comm.callServer('', 'loadQuestions');
});

YAHOO.example.getDataTipText = function( item, index, series )
{
    var toolTipText = series.displayName + " for " + item.month;
//    toolTipText += "\n" + YAHOO.example.formatCurrencyAxisLabel( item[series.yField] );
    return toolTipText;
}

