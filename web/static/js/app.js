// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
import "phoenix_html"
import "vue-resource"

var initial = `This is a sample text. Press "find stress" to find the stressed syllables in this short little text.

Are Americans good at keeping records? For the record, I am recording the answer.

They conducted an investigation. It was exemplary conduct.

This word does not exist: adsfghjkl`;

function format_html_whitespaces(line) {
    return line.map(word =>
        word.map(item => item.replace(" ", "&nbsp;")));
}

var app = new Vue({
    el: '#app',
    data: {
        textinput: initial,
        results: null
    },
    methods: {
        onSubmit: function () {
            var body = { text: this.$refs.text.value }
            this.$http.post('/api/v1/get-stress', body).then(response => {
                // Whitespaces won't show up otherwise without this transformation
                var formatted = response.body.result.map(line =>
                    format_html_whitespaces(line));
                this.results = formatted;
            }, response => {
            });
        }
    }
})

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

// import socket from "./socket"
