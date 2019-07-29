module main

import (
	rand 
	http
	json
) 

const (
	CLIENT_ID     = ''
	CLIENT_SECRET = ''
)

struct GitHubUser {
	login string
}

const (
	RANDOM = 'qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890'
)

fn random_string(len int) string {
	mut buf := [byte(0); len]
	for i := 0; i < len; i++ {
		idx := rand.next(RANDOM.len)
		buf[i] = RANDOM[idx]
	}
	return string(buf) 
}

fn (app mut App) oauth_cb() {
	code := app.vweb.req.url.all_after('code=')
	println(code)
	if code == '' {
		return
	}
	d := 'client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET&code=$code'
	resp := http.post('https://github.com/login/oauth/access_token', d)
	token := resp.find_between('access_token=', '&')
	mut req := http.new_request('GET', 'https://api.github.com/user?access_token=$token', '')
	req.add_header('User-Agent', 'V http client')
	user_js := req.do()
	gh_user := json.decode(GitHubUser, user_js.body) or {
		println('cant decode')
		return
	}
	login := gh_user.login.replace(' ', '')
	mut random_id := random_string(20)
	app.db.exec_param2('insert into users (name, random_id) values ($1, $2)', login, random_id)
	// Fetch the new or already existing user and set cookies
	user_id := app.db.q_int('select id from users where name=\'$login\' ')
	random_id = app.db.q_string('select random_id from users where name=\'$login\' ')
	app.vweb.set_cookie('id', user_id.str())
	app.vweb.set_cookie('q', random_id)
	app.vweb.redirect('/')
}

fn (app mut App) auth() {
	id := app.vweb.get_cookie('id').int()
	random_id := app.vweb.get_cookie('q')
	if id != 0 {
		cur_user := app.retrieve_user(id, random_id) or {
			return
		}
		app.cur_user = cur_user
	}
}
