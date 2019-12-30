module main

import (
	rand
	net.http
	json
	os
)

const (
	//CLIENT_ID     = ''
	//CLIENT_SECRET = ''
	//oauth_client_id = os.getenv('VORUM_OAUTH_CLIENT_ID')
	//oauth_client_secret = os.getenv('VORUM_OAUTH_SECRET')
	CLIENT_ID = os.getenv('VORUM_OAUTH_CLIENT_ID')
	CLIENT_SECRET = os.getenv('VORUM_OAUTH_SECRET')
)

struct GitHubUser {
	login string
}

const (
	RANDOM = 'qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890'
)

fn random_string(len int) string {
	mut buf := [byte(0)].repeat(len)
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
	resp := http.post('https://github.com/login/oauth/access_token', d) or { return }
	token := resp.text.find_between('access_token=', '&')
	mut req := http.new_request('GET', 'https://api.github.com/user?access_token=$token', '') or { return }
	req.add_header('User-Agent', 'V http client')
	user_js := req.do() or { return }
	gh_user := json.decode(GitHubUser, user_js.text) or {
		println('cant decode')
		return
	}
	login := gh_user.login.replace(' ', '')
	if login == '' {
		app.vweb.text('Failed to authenticate')
		return
	}
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
	id_str := app.vweb.get_cookie('id') or { '0' }
	id := id_str.int()
	random_id := app.vweb.get_cookie('q') or {
		println('cant get random_id')
		return
	}
	//println('auth() id=$id q=$random_id')
	if id != 0 {
		user := app.retrieve_user(id, random_id) or {
			println('user not found (id=$id, random_id=$random_id)')
			return
		}
		if user.is_banned {
			app.vweb.text('Your account was banned.')
			return
		}
		app.user = user
		app.logged_in = true
	}
}
