module main

import net.http
import json
import os
import vweb

const (
	// oauth_client_id = os.getenv('VORUM_OAUTH_CLIENT_ID')
	// oauth_client_secret = os.getenv('VORUM_OAUTH_SECRET')
	client_id     = os.getenv('VORUM_OAUTH_CLIENT_ID')
	client_secret = os.getenv('VORUM_OAUTH_SECRET')
)

struct GitHubUser {
	login string
}

fn (mut app App) oauth_cb() vweb.Result {
	code := app.req.url.all_after('code=')
	if code == '' {
		return app.text('Code is required')
	}

	request_params := 'client_id=${client_id}&client_secret=${client_secret}&code=${code}'
	response := http.post('https://github.com/login/oauth/access_token', request_params) or {
		return app.ok('')
	}
	token := response.body.find_between('access_token=', '&')
	user_js := http.get('https://api.github.com/user?access_token=${token}') or {
		return app.ok('')
	}
	gh_user := json.decode(GitHubUser, user_js.body) or { return app.text('Cant decode') }

	login := gh_user.login.replace(' ', '')
	if login == '' {
		return app.text('Failed to authenticate')
	}

	app.db.exec_param('insert into users (name) values ($1, $2)', login) or { return app.ok('') }

	// Fetch the new or already existing user and set cookies
	user_id := app.db.q_int('select id from users where name=\'${login}\' ') or {
		return app.ok('')
	}
	app.set_cookie(http.Cookie{ name: 'id', value: user_id.str() })
	app.redirect('/')

	return app.ok('')
}

fn (mut app App) auth() {
	id_str := app.get_cookie('id') or { '0' }
	id := id_str.int()

	if id != 0 {
		user := app.get_user(id) or {
			app.warn('User not found id=${id}')
			return
		}
		if user.is_banned {
			app.text('Your account was banned.')
			return
		}
		app.user = user
		app.logged_in = true
	}
}
