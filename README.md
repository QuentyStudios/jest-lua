<h1 align="center">Jest Roblox</h1>
<div align="center">
	<a href="https://github.com/Roblox/jest-roblox/actions?query=workflow%3ACI">
		<img src="https://github.com/Roblox/jest-roblox/workflows/CI/badge.svg" alt="GitHub Actions Build Status" />
	</a>
	<a href="https://roblox.github.io/testez">
			<img src="https://img.shields.io/badge/docs-website-green.svg" alt="Documentation" />
	</a>
</div>

<div align="center">
	BDD-style Roblox Lua testing framework
</div>

<div>&nbsp;</div>

Jest Roblox can run within Roblox itself, as well as inside roblox-cli for testing on CI systems.

We use Jest Roblox at Roblox for testing our apps, in-game core scripts, built-in Roblox Studio plugins, as well as libraries like [Roact](https://github.com/Roblox/roact) and [Rodux](https://github.com/Roblox/rodux).

## Inspiration and Prior Work
Jest Roblox is a Roblox port of the open source JavaScript testing framework [Jest](https://github.com/facebook/jest). Modules in the `modules` directory are  aligned to [v26.5.3](https://github.com/facebook/jest/tree/v26.5.3) of Jest, but the current public API is compatible with TestEZ [v0.4.0](https://github.com/Roblox/testez/tree/v0.4.0) while we complete our alignment.

It is also an evolution of an older test framework used at Roblox, [TestEZ](https://github.com/Roblox/TestEZ). It is currently forked from [commit 4bee8e3](https://github.com/Roblox/testez/tree/4bee8e3922bfdb0314a1af753ab5abfceea4dc79) of TestEZ. As such, the `expect` syntax is based on Chai, a JavaScript assertion library commonly used with Mocha, but it will soon be modified to align to Jest's `expect` syntax.

---

## Running Jest Roblox tests
You need to create a GitHub Access Token:
* GitHub.com -> Settings -> Developer Settings -> Personal Access Tokens
* On that same page, you then need to click Enable SSO
* BE SURE TO COPY THE ACCESS TOKEN SOMEWHERE 

```
npm login --registry=https://npm.pkg.github.com/ --scope=@roblox
```
For your password here, you will enter the GitHub Access Token from the instructions above.

```
npm install --global @roblox/rbx-aged-cli
```

Before you can use rbx-aged-cli, you need to be logged into the VPN so the Artifactory repository is accessible.

```
mkdir ~/bin
rbx-aged-cli download roblox-cli --dst ~/bin
export PATH=$PATH:~/bin
roblox-cli --help
git clone git@github.com:Roblox/jest-roblox.git
cd jest-roblox
```

Foreman uses Rust, so you'll have to install Rust first.

```
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
export PATH=$PATH:$HOME/.cargo/bin
cargo install foreman
foreman github-auth  # your auth token should be in your ~/.npmrc
foreman install
export PATH=$PATH:~/.foreman/bin/
```

Now you can run the tests, edit code, and contribute!

```
rotrieve install
bin/ci.sh
```

---

## Contributing
Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for information.

## License
Jest Roblox is available under the Apache 2.0 license. See [LICENSE](LICENSE) for details.
