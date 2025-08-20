 alias _alias="nano /etc/profile.d/aliases.sh;"
        alias _resource=". /etc/profile.d/aliases.sh"

        alias dsp='docker system prune'
        alias dip='docker image prune'
        alias dvp='docker volume prune'
        alias dcp='dk container prune'
        alias dbp='dk builder prune'

        alias dc='docker compose'
        alias dc_p='dc -f docker-compose.prod.yml'
        alias dk='docker'
        alias ds='dk stack'

        alias dcr='dc run --rm --remove-orphans'
        alias dce='dc exec'
        alias dcl='dc logs'


        alias dcrp='dc_p run --rm --remove-orphans'
        alias dcep='dc_p exec'
        alias dclp='dc_p logs'

        alias dks="dk stats"
        alias dke='dk exec -it'
        alias dkr="dk run -it --rm"
        alias dkl='dk logs'
        alias dkdf="dk system df"
        alias dcs="dc stats"

