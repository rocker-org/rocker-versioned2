
## Runs as user 

install2.r languageserver lintr styler profvis httpgd
sudo pip install radian

## unfortunately these don't run and complete, but instead tries to bring up code-server
#code-server install Ikuyadeu.r
#code-server install RDebugger.r-debugger

echo "options(vsc.use_httpgd = TRUE)" >> ~/.Rprofile


