#==============================================================================
#  Makefile для Containerlab: iptables-lab
#  Топология: attacker (10.0.1.2) -- firewall -- victim (10.0.2.2)
# ==============================================================================

# --- Параметры лаборатории ----------------------------------------------------
LAB_NAME   := iptables-lab
TOPOLOGY   := $(LAB_NAME).clab.yml

# Имена контейнеров, как их создаёт Containerlab
C_ATTACKER := clab-$(LAB_NAME)-attacker
C_FIREWALL := clab-$(LAB_NAME)-firewall
C_VICTIM   := clab-$(LAB_NAME)-victim

# Цвета для вывода
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED   := \033[0;31m
NC    := \033[0m

# --- Псевдонимы ---------------------------------------------------------------
.PHONY: help deploy inspect status web \
        sh-attacker sh-firewall sh-victim \
        stop start restart \
        destroy destroy-clean \
        logs-firewall logs-attacker logs-victim \
        flush-firewall rules-firewall

# --- Справка ------------------------------------------------------------------
help:
	@echo -e "$(GREEN)Containerlab Makefile — $(LAB_NAME)$(NC)"
	@echo -e ""
	@echo -e "$(YELLOW)Развёртывание:$(NC)"
	@echo -e "  make deploy            — развернуть лабораторию"
	@echo -e "  make destroy           — удалить лабораторию (с сохранением конфигов)"
	@echo -e "  make destroy-clean     — полный сброс (удалить всё)"
	@echo -e ""
	@echo -e "$(YELLOW)Просмотр:$(NC)"
	@echo -e "  make inspect           — статус узлов (containerlab)"
	@echo -e "  make status            — статус через docker ps"
	@echo -e "  make web               — развернуть веб-интерфейс с диаграммой"
	@echo -e ""
	@echo -e "$(YELLOW)Терминалы:$(NC)"
	@echo -e "  make sh-firewall       — войти в firewall (главный узел)"
	@echo -e "  make sh-attacker       — войти в attacker"
	@echo -e "  make sh-victim         — войти в victim"
	@echo -e ""
	@echo -e "$(YELLOW)Управление контейнерами:$(NC)"
	@echo -e "  make stop              — остановить все контейнеры (без удаления)"
	@echo -e "  make start             — запустить остановленные контейнеры"
	@echo -e "  make restart           — перезапустить все контейнеры"
	@echo -e ""
	@echo -e "$(YELLOW)Отладка:$(NC)"
	@echo -e "  make rules-firewall    — показать правила iptables на firewall"
	@echo -e "  make flush-firewall    — очистить все правила iptables на firewall"
	@echo -e "  make logs-firewall     — логи firewall"
	@echo -e "  make logs-attacker     — логи attacker"
	@echo -e "  make logs-victim       — логи victim"

# --- Развёртывание ------------------------------------------------------------
deploy:
	@echo -e "$(GREEN)>>> Разворачиваем $(LAB_NAME)$(NC)"
	sudo containerlab deploy -t $(TOPOLOGY)
	@echo -e "$(GREEN)>>> Готово. Узлы:$(NC)"
	@sudo containerlab inspect -t $(TOPOLOGY)

# --- Просмотр -----------------------------------------------------------------
inspect:
	@sudo containerlab inspect -t $(TOPOLOGY)

status:
	@echo -e "$(YELLOW)Контейнеры лаборатории:$(NC)"
	@docker ps -a --filter "label=clab-node-kind" \
		--format "table {{.Names}}\t{{.Status}}\t{{.Image}}"

web:
	@echo -e "$(YELLOW)Разворачиваем веб-сервер на порту 50080:$(NC)"
	@sudo containerlab graph

# --- Терминалы ----------------------------------------------------------------
sh-firewall:
	@echo -e "$(GREEN)>>> Вход в firewall ($(C_FIREWALL))$(NC)"
	@docker exec -it $(C_FIREWALL) bash

sh-attacker:
	@echo -e "$(GREEN)>>> Вход в attacker ($(C_ATTACKER))$(NC)"
	@docker exec -it $(C_ATTACKER) sh

sh-victim:
	@echo -e "$(GREEN)>>> Вход в victim ($(C_VICTIM))$(NC)"
	@docker exec -it $(C_VICTIM) bash

# --- Управление контейнерами --------------------------------------------------
stop:
	@echo -e "$(YELLOW)>>> Останавливаем контейнеры (без удаления)$(NC)"
	-docker stop $(C_ATTACKER) $(C_FIREWALL) $(C_VICTIM)

start:
	@echo -e "$(GREEN)>>> Запускаем остановленные контейнеры$(NC)"
	-docker start $(C_ATTACKER) $(C_FIREWALL) $(C_VICTIM)

restart: stop start

# --- Удаление -----------------------------------------------------------------
destroy:
	@echo -e "$(RED)>>> Удаляем лабораторию (конфиги сохраняются)$(NC)"
	sudo containerlab destroy -t $(TOPOLOGY)

destroy-clean:
	@echo -e "$(RED)>>> Полный сброс лаборатории (включая конфиги)$(NC)"
	sudo containerlab destroy -t $(TOPOLOGY) --cleanup

# --- Отладка: iptables --------------------------------------------------------
rules-firewall:
	@echo -e "$(YELLOW)Правила iptables на firewall:$(NC)"
	@docker exec $(C_FIREWALL) iptables -L -v -n --line-numbers

flush-firewall:
	@echo -e "$(RED)>>> Очищаем все правила iptables на firewall$(NC)"
	@docker exec $(C_FIREWALL) iptables -F
	@docker exec $(C_FIREWALL) iptables -X
	@docker exec $(C_FIREWALL) iptables -t nat -F
	@docker exec $(C_FIREWALL) iptables -P FORWARD ACCEPT
	@docker exec $(C_FIREWALL) iptables -P INPUT ACCEPT
	@docker exec $(C_FIREWALL) iptables -P OUTPUT ACCEPT
	@echo -e "$(GREEN)>>> Готово$(NC)"

# --- Логи ---------------------------------------------------------------------
logs-firewall:
	@docker logs -f $(C_FIREWALL)

logs-attacker:
	@docker logs -f $(C_ATTACKER)

logs-victim:
	@docker logs -f $(C_VICTIM)
