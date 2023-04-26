version: STSv1
mode: ${mode}
max_age: ${max_age}
%{for hostname in mx ~}
mx: ${hostname}
%{endfor ~}
