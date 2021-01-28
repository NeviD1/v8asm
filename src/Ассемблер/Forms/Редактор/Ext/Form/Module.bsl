﻿&НаКлиенте
Перем ЗначениеТочкиВходаПроцедуры;


// Licensed with
// https://github.com/Lead-Tools/ripper/blob/master/LICENSE
&НаСервере
Function Parse(Src, Pos = 1) Export
	List = New Array;
	Pos = Pos + 1;
	Chr = Mid(Src, Pos, 1);
	If Chr = Chars.LF Then
		Pos = Pos + 1;
		Chr = Mid(Src, Pos, 1);
	EndIf;
	Beg = Pos;
	While Chr <> "" Do
		If Chr = "{" Then
			List.Add(Parse(Src, Pos));
			Pos = Pos + 1;
			Chr = Mid(Src, Pos, 1);
			If Chr = Chars.LF Then
				Pos = Pos + 1;
				Chr = Mid(Src, Pos, 1);
			EndIf;
			Beg = Pos;
		ElsIf Chr = "," Then
			If Beg < Pos Then
				List.Add(Mid(Src, Beg, Pos - Beg));
			EndIf;
			Pos = Pos + 1;
			Chr = Mid(Src, Pos, 1);
			If Chr = Chars.LF Then
				Pos = Pos + 1;
				Chr = Mid(Src, Pos, 1);
			EndIf;
			Beg = Pos;
		ElsIf Chr = "}" Then
			If Beg < Pos Then
				List.Add(Mid(Src, Beg, Pos - Beg));
			EndIf;
			Break;
		ElsIf Chr = """" Then
			While Chr = """" Do
				Pos = Pos + 1;
				While Mid(Src, Pos, 1) <> """" Do
					Pos = Pos + 1;
				EndDo;
				Pos = Pos + 1;
				Chr = Mid(Src, Pos, 1);
			EndDo;
		Else
			Pos = Pos + 1;
			Chr = Mid(Src, Pos, 1);
		EndIf;
	EndDo;
	Return List;
EndFunction // Parse()

&НаСервере
Процедура ПриСозданииНаСервере(Отказ, СтандартнаяОбработка)
	РасшифровкаОперацийТЗ = ЗагрузитьРасшифровкуБайтКода();
	ЗаполнитьСписокОпКодов(РасшифровкаОперацийТЗ);
	ЗначениеВРеквизитФормы(РасшифровкаОперацийТЗ, "РасшифровкаОпераций");
КонецПроцедуры


&НаСервере
Процедура ОткрытьНаСервере(Знач Адрес)
	
	Операции.Очистить();
	ЭтаФорма.Константы.Очистить();
	Переменные.Очистить();
	Процедуры.Очистить();
	
	РезультатРазбора = ПрочитатьМодуль(Адрес);

	Для Сч = 1 По РезультатРазбора.ВГраница() Цикл
		Блок = РезультатРазбора[Сч];
		Если Блок[0] = """Cmd""" Тогда
			ЗаполнитьОперации(Блок);
		ИначеЕсли Блок[0] = """Const""" Тогда
			ЗаполнитьКонстанты(Блок);
		ИначеЕсли Блок[0] = """Var""" Тогда
			ЗаполнитьПеременные(Блок, Переменные);
		ИначеЕсли Блок[0] = """Proc""" Тогда
			ЗаполнитьПроцедуры(Блок);
		КонецЕсли;
	КонецЦикла;
	
КонецПроцедуры

&НаСервере
Процедура ЗаполнитьОперации(Знач Блок)

	ЧислоКоманд = Число(Блок[1]);
	ТочкаВхода = Число(Блок[2]);
	СчетчикАдресов = 0;
	Для Сч = 3 По ЧислоКоманд+2 Цикл
		Команда = Блок[Сч];
		СтрокаОперации = Операции.Добавить();
		СтрокаОперации.Адрес = СчетчикАдресов;
		Если СчетчикАдресов = ТочкаВхода Тогда
			СтрокаОперации.ЭтоТочкаВхода = 1;
		КонецЕсли;
		СтрокаОперации.КодОперации = Число(Команда[0]);
		СтрокаОперации.Аргумент = Число(Команда[1]);
		Если СтрокаОперации.КодОперации < РасшифровкаОпераций.Количество() Тогда
			СтрокаОписания = РасшифровкаОпераций[СтрокаОперации.КодОперации];
			СтрокаОперации.ИмяОперации = СтрокаОписания.Мнемоника;
			СтрокаОперации.Описание = СтрокаОписания.Название + Символы.ПС + СтрокаОписания.ОписаниеАргумента;
		Иначе
			СтрокаОперации.ИмяОперации = СтрокаОперации.КодОперации;
			СтрокаОперации.Описание = "ОпКод еще не исследован";
		КонецЕсли;
		
		СчетчикАдресов = СчетчикАдресов + 1;
	КонецЦикла;

КонецПроцедуры // ЗаполнитьОперации()

&НаСервере
Процедура ЗаполнитьСписокОпКодов(Знач РасшифровкаОпераций)

	Элемент = Элементы.ОперацииИмяОперации;
	Для Каждого Стр Из РасшифровкаОпераций Цикл
		Элемент.СписокВыбора.Добавить(Стр.Мнемоника);
	КонецЦикла;
	
КонецПроцедуры // ЗаполнитьСписокОпКодов()

&НаСервере
Процедура ЗаполнитьКонстанты(Знач Блок)

	Типы = Новый Соответствие;
	Типы.Вставить("""N""", "Число");
	Типы.Вставить("""S""", "Строка");
	Типы.Вставить("""B""", "Булево");
	Типы.Вставить("""D""", "Дата");
	Типы.Вставить("""L""", "Null");
	Типы.Вставить("""U""", "Неопределено");
	
	ЧислоКонстант = Число(Блок[1]);
	Счетчик = 0;
	Для Сч = 2 По ЧислоКонстант+1 Цикл
		Константа = Блок[Сч];
		СтрКонстанты = ЭтаФорма.Константы.Добавить();
		СтрКонстанты.Номер = Счетчик;
		СтрКонстанты.Значение  = ДесериализоватьСтроку(Константа[1]);
		СтрКонстанты.ТипКонстанты = Типы[Константа[0]];
		Счетчик = Счетчик + 1;
	КонецЦикла;

КонецПроцедуры // ЗаполнитьКонстанты()

&НаСервере
Процедура ЗаполнитьПеременные(Знач Блок, Знач ТаблицаПриемник)

	ЧислоПеременных = Число(Блок[1]);
	Счетчик = 0;
	Для Сч = 2 По ЧислоПеременных + 1 Цикл
		Переменная = Блок[Сч];
		СтрПерем = ТаблицаПриемник.Добавить();
		СтрПерем.Номер = Счетчик;
		СтрПерем.ИмяПеременной = СтрЗаменить(Переменная[0],"""", "");
		СтрПерем.ФлагиПеременной = Число(Переменная[1]);
		Счетчик = Счетчик + 1;
	КонецЦикла;

КонецПроцедуры // ЗаполнитьПеременные()

&НаСервере
Процедура ЗаполнитьПроцедуры(Знач Блок)

	ЧислоПроцедур = Число(Блок[1]);
	Счетчик = 0;
	Для Сч = 2 По ЧислоПроцедур + 1 Цикл
		
		Проц = Блок[Сч];
		СтрокаПроцедуры = Процедуры.Добавить();
		СтрокаПроцедуры.Номер = Счетчик;
		СтрокаПроцедуры.ИмяПроцедуры = СтрЗаменить(Проц[0],"""", "");
		СтрокаПроцедуры.ТипПроцедуры = Число(Проц[1]);
		СтрокаПроцедуры.ЧислоАргументов = Число(Проц[2]);
		СтрокаПроцедуры.ТочкаВхода = Число(Проц[3]);
		
		Если СтрокаПроцедуры.ТипПроцедуры < 32 Тогда
			Операция = Операции[СтрокаПроцедуры.ТочкаВхода];
			Операция.ЭтоТочкаВхода = 2;
		КонецЕсли;
		
		Для СчОпциональный = 4 По Проц.ВГраница() Цикл
			Если Проц[СчОпциональный][0] = """Var""" Тогда
				ЗаполнитьПеременные(Проц[СчОпциональный], СтрокаПроцедуры.Переменные);
			КонецЕсли;
			Если Проц[СчОпциональный][0] = """DefPrm""" Тогда
				ЗаполнитьУмолчанияПараметров(Проц[СчОпциональный], СтрокаПроцедуры.Умолчания);
			КонецЕсли;
		КонецЦикла;
		Счетчик = Счетчик + 1;
	КонецЦикла;

КонецПроцедуры

&НаСервере
Процедура ЗаполнитьУмолчанияПараметров(Блок, ТаблицаПриемник)

	Типы = Новый Соответствие;
	Типы.Вставить("""N""", "Число");
	Типы.Вставить("""S""", "Строка");
	Типы.Вставить("""B""", "Булево");
	Типы.Вставить("""D""", "Дата");
	Типы.Вставить("""L""", "Null");
	Типы.Вставить("""U""", "Неопределено");
	Типы.Вставить("""""", "Нет значения");
	
	ЧислоУмолчаний = Число(Блок[1]);
	Счетчик = 0;
	
	Для Сч = 2 По ЧислоУмолчаний+1 Цикл
		
		Описание = Блок[Сч];
		Стр = ТаблицаПриемник.Добавить();
		Стр.Тип = Типы[Описание[0]];
		Стр.Номер = Счетчик;
		
		Если ПустаяСтрока(Стр.Тип) Тогда
			Стр.Значение = "";
		ИначеЕсли Стр.Тип = "Строка" Тогда
			Стр.Значение = ДесериализоватьСтроку(Описание[1]);
		ИначеЕсли Описание.Количество() = 2 Тогда
			Стр.Значение = Описание[1];
		КонецЕсли;
		Счетчик = Счетчик + 1;
		
	КонецЦикла;

КонецПроцедуры


&НаСервере
Функция ЗагрузитьРасшифровкуБайтКода()

	Обработка = РеквизитФормыВЗначение("Объект");
	Макет     = Обработка.ПолучитьМакет("Описание");
	
	ТаблицаРезультат = Новый ТаблицаЗначений;
	ТаблицаРезультат.Колонки.Добавить("Мнемоника");
	ТаблицаРезультат.Колонки.Добавить("Код");
	ТаблицаРезультат.Колонки.Добавить("Название");
	ТаблицаРезультат.Колонки.Добавить("ОписаниеАргумента");
	ТаблицаРезультат.Колонки.Добавить("ЧислоУбираемыхЗначений");
	ТаблицаРезультат.Колонки.Добавить("ЧислоДобавляемыхЗначений");
	
	Для Сч = 2 По Макет.ВысотаТаблицы Цикл
		СтрТаб = ТаблицаРезультат.Добавить();
		СтрТаб.Мнемоника = Макет.Область(Сч,1).Текст;
		Если ПустаяСтрока(СтрТаб.Мнемоника) Тогда
			СтрТаб.Мнемоника = Макет.Область(Сч,3).Текст;
		КонецЕсли;
		СтрТаб.Код = Число(Макет.Область(Сч,2).Текст);
		СтрТаб.Название = Макет.Область(Сч,3).Текст;
		СтрТаб.ОписаниеАргумента = Макет.Область(Сч,4).Текст;
	КонецЦикла;

	Возврат ТаблицаРезультат;
	
КонецФункции // ЗагрузитьРасшифровкуБайтКода()

&НаСервере
Функция ПрочитатьМодуль(Знач Адрес)
	
	ДД = ПолучитьИзВременногоХранилища(Адрес);
	Чтение = Новый ЧтениеТекста(ДД.ОткрытьПотокДляЧтения());
	Текст = Чтение.Прочитать();
	
	Возврат Parse(Текст);

КонецФункции

&НаКлиенте
Процедура ОткрытьФайл(Команда)
	НачатьПомещениеФайла(Новый ОписаниеОповещения("ОбработкаВыбораФайла", ЭтотОбъект));
КонецПроцедуры

&НаКлиенте
Процедура ОбработкаВыбораФайла(Результат, Адрес, ВыбранноеИмя, Контекст) Экспорт

	Если Результат Тогда
		ОткрытьНаСервере(Адрес);
	КонецЕсли;

КонецПроцедуры // ОбработкаВыбораФайла()

&НаКлиентеНаСервереБезКонтекста
Функция ДесериализоватьСтроку(Знач СтрокаИзПотока)

	Возврат Вычислить(СтрЗаменить(СтрокаИзПотока, Символы.ПС, Символы.ПС + "|"));

КонецФункции // ДесериализоватьСтроку()


&НаКлиенте
Процедура ПроцедурыПеременныеФлагиПеременнойНачалоВыбора(Элемент, ДанныеВыбора, СтандартнаяОбработка)
	
	СтандартнаяОбработка = Ложь;
	П = Новый Структура;
	П.Вставить("ТекущееЗначение", Элементы.ПроцедурыПеременные.ТекущиеДанные.ФлагиПеременной);
	ОткрытьФорму("ВнешняяОбработка.Ассемблер.Форма.ФлагиПеременной", П, Элемент);
	
КонецПроцедуры


&НаКлиенте
Процедура ПеременныеФлагиПеременнойНачалоВыбора(Элемент, ДанныеВыбора, СтандартнаяОбработка)
	СтандартнаяОбработка = Ложь;
	П = Новый Структура;
	П.Вставить("ТекущееЗначение", Элементы.Переменные.ТекущиеДанные.ФлагиПеременной);
	ОткрытьФорму("ВнешняяОбработка.Ассемблер.Форма.ФлагиПеременной", П, Элемент);
КонецПроцедуры

&НаКлиенте
Процедура ПеременныеПриОкончанииРедактирования(Элемент, НоваяСтрока, ОтменаРедактирования)
	Если Не ОтменаРедактирования Тогда
		ПеренумероватьСтрокиТаблицы(Переменные, "Номер");
	КонецЕсли;
КонецПроцедуры

&НаКлиенте
Процедура ПеременныеПослеУдаления(Элемент)
	ПеренумероватьСтрокиТаблицы(Переменные, "Номер");
КонецПроцедуры

&НаКлиенте
Процедура ПроцедурыТипПроцедурыНачалоВыбора(Элемент, ДанныеВыбора, СтандартнаяОбработка)
	СтандартнаяОбработка = Ложь;
	П = Новый Структура;
	П.Вставить("ТекущееЗначение", Элементы.Процедуры.ТекущиеДанные.ТипПроцедуры);
	ОткрытьФорму("ВнешняяОбработка.Ассемблер.Форма.ФлагиПроцедуры", П, Элемент);
КонецПроцедуры


&НаКлиенте
Процедура ТочкаВхода(Команда)
	ПоказатьВводЧисла(Новый ОписаниеОповещения("ТочкаВходаЗавершение", ЭтаФорма), ТочкаВхода, "Укажите адрес",10,0);
КонецПроцедуры

&НаКлиенте
Процедура ТочкаВходаЗавершение(Число, ДополнительныеПараметры) Экспорт
	
	Если Число = Неопределено Тогда
		Возврат;
	КонецЕсли;
	
	Если Число > Операции.Количество() или Число < 0 Тогда
		Сообщить("Выбранное значение выходит за границы адресов кода");
		Возврат;
	КонецЕсли;
	
	Операции[ТочкаВхода].ЭтоТочкаВхода = 0;
	Операции[Число].ЭтоТочкаВхода = 1;
	ТочкаВхода = Число;
	
КонецПроцедуры

&НаКлиенте
Процедура ПроцедурыПередОкончаниемРедактирования(Элемент, НоваяСтрока, ОтменаРедактирования, Отказ)
	Если НоваяСтрока и ОтменаРедактирования Тогда
		Возврат;
	КонецЕсли;
	
	Если Элементы.Процедуры.ТекущиеДанные.ТипПроцедуры >=32 Тогда
		Возврат;
	КонецЕсли;
	
	ТекЗначениеТВ = Элементы.Процедуры.ТекущиеДанные.ТочкаВхода;
	Если ТекЗначениеТВ < 0 ИЛИ ТекЗначениеТВ > Операции.Количество() Тогда
		Сообщить("Выбранное значение точки входа выходит за границы адресов кода");
		Отказ = Истина;
		Возврат;
	КонецЕсли;
	
	Операции[ЗначениеТочкиВходаПроцедуры].ЭтоТочкаВхода = 0;
	Операции[ТекЗначениеТВ].ЭтоТочкаВхода = 2;
	
КонецПроцедуры

&НаКлиенте
Процедура ПроцедурыПриНачалеРедактирования(Элемент, НоваяСтрока, Копирование)
	ЗначениеТочкиВходаПроцедуры = Элементы.Процедуры.ТекущиеДанные.ТочкаВхода;
КонецПроцедуры

&НаКлиенте
Процедура ПроцедурыПриОкончанииРедактирования(Элемент, НоваяСтрока, ОтменаРедактирования)
	Если Не ОтменаРедактирования Тогда
		ПеренумероватьСтрокиТаблицы(Процедуры, "Номер");
	КонецЕсли;
КонецПроцедуры

&НаКлиенте
Процедура ПроцедурыПослеУдаления(Элемент)
	ПеренумероватьСтрокиТаблицы(Процедуры, "Номер");
КонецПроцедуры

&НаСервере
Функция СправкаПоКомандамНаСервере()
	ОбработкаОбъект = РеквизитФормыВЗначение("Объект");
	Возврат ОбработкаОбъект.ПолучитьМакет("Описание");
КонецФункции

&НаКлиенте
Процедура СправкаПоКомандам(Команда)
	ТД = СправкаПоКомандамНаСервере();
	ТД.Показать("Описание команд");
КонецПроцедуры

&НаКлиенте
Процедура ОперацииПослеУдаления(Элемент)
	ПеренумероватьАдресаКоманд();
КонецПроцедуры

&НаКлиенте
Процедура ПеренумероватьАдресаКоманд()
	ПеренумероватьСтрокиТаблицы(Операции, "Адрес");
КонецПроцедуры

&НаКлиентеНаСервереБезКонтекста
Процедура ПеренумероватьСтрокиТаблицы(Знач Таблица, Знач КолонкаНомер)
	Для Сч = 0 По Таблица.Количество() - 1 Цикл
		Таблица[Сч][КолонкаНомер] = Сч;
	КонецЦикла;
КонецПроцедуры // ПеренумероватьСтрокиТаблицы()


&НаКлиенте
Процедура Перенумеровать(Команда)
	ПеренумероватьАдресаКоманд();
	Точки = Операции.НайтиСтроки(Новый Структура("ЭтоТочкаВхода", 1));
	Для Каждого Точка Из Точки Цикл
		Точка.ЭтоТочкаВхода = 0;
	КонецЦикла;
	
	Точки = Операции.НайтиСтроки(Новый Структура("ЭтоТочкаВхода", 2));
	Для Каждого Точка Из Точки Цикл
		Точка.ЭтоТочкаВхода = 0;
	КонецЦикла;
	
	Для Каждого Проц Из Процедуры Цикл
		Если Проц.ТипПроцедуры < 32 и Проц.ТочкаВхода < Операции.Количество() и Проц.ТочкаВхода >= 0 Тогда
			Операции[Проц.ТочкаВхода].ЭтоТочкаВхода = 2;
		КонецЕсли;
	КонецЦикла;
	
	Операции[ТочкаВхода].ЭтоТочкаВхода = 1;
	
КонецПроцедуры

&НаСервере
Функция СохранитьНаСервере()

	БОМ = Новый БуферДвоичныхДанных(3);
	БОМ[0] = 239;
	БОМ[1] = 187;
	БОМ[2] = 191;
	Поток = Новый ПотокВПамяти(1024);
	Поток.Записать(БОМ,0, 3);
	СериализоватьМодуль(Поток);
	ДД = Поток.ЗакрытьИПолучитьДвоичныеДанные();
	
	Возврат ПоместитьВоВременноеХранилище(ДД);

КонецФункции // СохранитьНаСервере()

#Область ФункцииЗаписиПотока

Процедура СериализоватьМодуль(Знач Поток)
	
	Запись = Новый ЗаписьТекста(Поток, КодировкаТекста.UTF8);
	КонтекстЗаписи = Новый Структура;
	КонтекстЗаписи.Вставить("Запись", Запись);
	КонтекстЗаписи.Вставить("Списки", Новый Массив);
	
	ЗаписатьМодуль(КонтекстЗаписи);
	Запись.Закрыть();
	
КонецПроцедуры

Функция СписокОткрыт(Знач КонтекстЗаписи)
	М = КонтекстЗаписи.Списки;
	Если М.Количество() Тогда
		Возврат М[М.ВГраница()];
	КонецЕсли;
	Возврат Ложь;
КонецФункции

Процедура ОткрытьСписок(Знач КонтекстЗаписи)
	М = КонтекстЗаписи.Списки;
	Если М.Количество() Тогда
		М[М.ВГраница()] = Истина;
	КонецЕсли;
КонецПроцедуры

Процедура ЗаписатьНачалоОбъекта(Знач КонтекстЗаписи, Знач СНовойСтроки = Истина)
	
	Если СписокОткрыт(КонтекстЗаписи) Тогда
		ЗаписатьРазделитель(КонтекстЗаписи);
	Иначе
		ОткрытьСписок(КонтекстЗаписи);
	КонецЕсли;
	
	Если СНовойСтроки Тогда
		ЗаписатьРазделительСтрок(КонтекстЗаписи);
	КонецЕсли;
	
	КонтекстЗаписи.Запись.Записать("{");
	КонтекстЗаписи.Списки.Добавить(Ложь);

КонецПроцедуры

Процедура ЗаписатьКонецОбъекта(Знач КонтекстЗаписи)
	
	КонтекстЗаписи.Запись.Записать("}");
	М = КонтекстЗаписи.Списки;
	М.Удалить(М.ВГраница());

КонецПроцедуры

Процедура ЗаписатьРазделитель(Знач КонтекстЗаписи)
	
	КонтекстЗаписи.Запись.Записать(",");

КонецПроцедуры

Процедура ЗаписатьРазделительСтрок(Знач КонтекстЗаписи)
	
	КонтекстЗаписи.Запись.Записать(Символы.ПС);

КонецПроцедуры

Процедура ЗаписатьЗначение(Знач КонтекстЗаписи, Знач Значение)

	Если СписокОткрыт(КонтекстЗаписи) Тогда
		ЗаписатьРазделитель(КонтекстЗаписи);
	Иначе
		ОткрытьСписок(КонтекстЗаписи);
	КонецЕсли;
	
	Если ТипЗнч(Значение) = Тип("Число") Тогда
		КонтекстЗаписи.Запись.Записать(Формат(Значение,"ЧН=0; ЧГ=0"));
	ИначеЕсли ТипЗнч(Значение) = Тип("Строка") Тогда
		КонтекстЗаписи.Запись.Записать(СтрШаблон("""%1""", СтрЗаменить(Значение, """", """""")));
	ИначеЕсли ТипЗнч(Значение) = Тип("Дата") Тогда
		КонтекстЗаписи.Запись.Записать(Формат(Значение,"ДФ=yyyyMMddHHmmss; ДП="));
	КонецЕсли;
	
КонецПроцедуры

&НаСервере
Процедура ЗаписатьМодуль(Знач КонтекстЗаписи)

	ЗаписатьНачалоОбъекта(КонтекстЗаписи, Ложь);
	ЗаписатьЗначение(КонтекстЗаписи, 1);
	ЗаписатьКоманды(КонтекстЗаписи);
	ЗаписатьКонстанты(КонтекстЗаписи);
	ЗаписатьПеременные(КонтекстЗаписи, Переменные);
	ЗаписатьПроцедуры(КонтекстЗаписи);
	ЗаписатьРазделительСтрок(КонтекстЗаписи);
	ЗаписатьКонецОбъекта(КонтекстЗаписи);

КонецПроцедуры // ЗаписатьМодуль()


&НаСервере
Процедура ЗаписатьКоманды(Знач КонтекстЗаписи)

	ЗаписатьНачалоОбъекта(КонтекстЗаписи);
	ЗаписатьЗначение(КонтекстЗаписи, "Cmd");
	ЗаписатьЗначение(КонтекстЗаписи, Операции.Количество());
	ЗаписатьЗначение(КонтекстЗаписи, ТочкаВхода);
	
	Для Каждого Оп Из Операции Цикл
		ЗаписатьНачалоОбъекта(КонтекстЗаписи);
		ЗаписатьЗначение(КонтекстЗаписи, Оп.КодОперации);
		ЗаписатьЗначение(КонтекстЗаписи, Оп.Аргумент);
		ЗаписатьКонецОбъекта(КонтекстЗаписи);
	КонецЦикла;
	ЗаписатьРазделительСтрок(КонтекстЗаписи);
	ЗаписатьКонецОбъекта(КонтекстЗаписи);

КонецПроцедуры // ЗаписатьКоманды()

&НаСервере
Процедура ЗаписатьКонстанты(КонтекстЗаписи)

	Если Не Константы.Количество() Тогда
		Возврат;
	КонецЕсли;
	
	ЗаписатьНачалоОбъекта(КонтекстЗаписи);
	ЗаписатьЗначение(КонтекстЗаписи, "Const");
	ЗаписатьЗначение(КонтекстЗаписи, Константы.Количество());
	
	Типы = Новый Соответствие;
	Типы.Вставить("Строка","S");
	Типы.Вставить("Число","N");
	Типы.Вставить("Булево","B");
	Типы.Вставить("Дата","D");
	Типы.Вставить("Null","L");
	Типы.Вставить("Неопределено","U");
	
	Для Каждого Конст Из ЭтаФорма.Константы Цикл
		ЗаписатьНачалоОбъекта(КонтекстЗаписи);
		ЗаписатьЗначение(КонтекстЗаписи, Типы[Конст.ТипКонстанты]);
		Если Конст.ТипКонстанты = "Строка" Тогда
			ЗаписатьЗначение(КонтекстЗаписи, Конст.Значение);
		ИначеЕсли Конст.ТипКонстанты = "Число" или Конст.ТипКонстанты = "Булево" Тогда
			ЗаписатьЗначение(КонтекстЗаписи, Число(Конст.Значение));
		ИначеЕсли Конст.ТипКонстанты = "Дата" Тогда
			ЗначениеДаты = Вычислить("'" + Конст.Значение + "'");
			ЗаписатьЗначение(КонтекстЗаписи, ЗначениеДаты);
		КонецЕсли;
		ЗаписатьКонецОбъекта(КонтекстЗаписи);
	КонецЦикла;
	ЗаписатьРазделительСтрок(КонтекстЗаписи);
	ЗаписатьКонецОбъекта(КонтекстЗаписи);

КонецПроцедуры // ЗаписатьКонстанты()

&НаСервере
Процедура ЗаписатьПеременные(Знач КонтекстЗаписи, Знач ТаблицаПеременных)

	Если Не ТаблицаПеременных.Количество() Тогда
		Возврат;
	КонецЕсли;
	
	ЗаписатьНачалоОбъекта(КонтекстЗаписи);
	ЗаписатьЗначение(КонтекстЗаписи, "Var");
	ЗаписатьЗначение(КонтекстЗаписи, ТаблицаПеременных.Количество());
	
	Для Каждого Переменная Из ТаблицаПеременных Цикл
		ЗаписатьНачалоОбъекта(КонтекстЗаписи);
		ЗаписатьЗначение(КонтекстЗаписи, Переменная.ИмяПеременной);
		ЗаписатьЗначение(КонтекстЗаписи, Переменная.ФлагиПеременной);
		ЗаписатьЗначение(КонтекстЗаписи, -1);
		ЗаписатьКонецОбъекта(КонтекстЗаписи);
	КонецЦикла;
	ЗаписатьРазделительСтрок(КонтекстЗаписи);
	ЗаписатьКонецОбъекта(КонтекстЗаписи);

КонецПроцедуры // ЗаписатьПеременные()

&НаСервере
Процедура ЗаписатьПроцедуры(Знач КонтекстЗаписи)

	ЗаписатьНачалоОбъекта(КонтекстЗаписи);
	ЗаписатьЗначение(КонтекстЗаписи, "Proc");
	ЗаписатьЗначение(КонтекстЗаписи, Процедуры.Количество());
	
	Для Каждого Проц Из Процедуры Цикл
		
		ЗаписатьНачалоОбъекта(КонтекстЗаписи);
		ЗаписатьЗначение(КонтекстЗаписи, Проц.ИмяПроцедуры);
		ЗаписатьЗначение(КонтекстЗаписи, Проц.ТипПроцедуры);
		ЗаписатьЗначение(КонтекстЗаписи, Проц.ЧислоАргументов);
		ЗаписатьЗначение(КонтекстЗаписи, Проц.ТочкаВхода);
		
		ЗаписатьПеременные(КонтекстЗаписи, Проц.Переменные);
		Если Проц.ТипПроцедуры < 32 Тогда
			Если Проц.Умолчания.Количество() = Проц.ЧислоАргументов Тогда
				ЗаписатьУмолчанияПараметров(КонтекстЗаписи, Проц.Умолчания);
			Иначе
				ВызватьИсключение СтрШаблон("Для процедуры %1 число параметров по умолчанию не совпадает с числом аргументов
				|Параметры не имеющие умолчаний все равно должны отражаться в таблице умолчаний с типом 'Нет значения'", Проц.ИмяПроцедуры);
			КонецЕсли;
		КонецЕсли;
		
		ЗаписатьРазделительСтрок(КонтекстЗаписи);
		ЗаписатьКонецОбъекта(КонтекстЗаписи);
		
	КонецЦикла;
	
	ЗаписатьРазделительСтрок(КонтекстЗаписи);
	ЗаписатьКонецОбъекта(КонтекстЗаписи);
	
КонецПроцедуры // ЗаписатьПроцедуры()

&НаСервере
Процедура ЗаписатьУмолчанияПараметров(Знач КонтекстЗаписи, Знач УмолчанияПараметров)
	
	ЗаписатьНачалоОбъекта(КонтекстЗаписи);
	ЗаписатьЗначение(КонтекстЗаписи, "DefPrm");
	ЗаписатьЗначение(КонтекстЗаписи, УмолчанияПараметров.Количество());
	
	Типы = Новый Соответствие;
	Типы.Вставить("Строка","S");
	Типы.Вставить("Число","N");
	Типы.Вставить("Булево","B");
	Типы.Вставить("Дата","D");
	Типы.Вставить("Null","L");
	Типы.Вставить("Неопределено","U");
	Типы.Вставить("Нет значения","");
	
	Для Каждого Умолчание Из УмолчанияПараметров Цикл
		ЗаписатьНачалоОбъекта(КонтекстЗаписи);
		
		ЗаписатьЗначение(КонтекстЗаписи, Типы[Умолчание.Тип]);
		Если Умолчание.Тип = "Строка" Тогда
			ЗаписатьЗначение(КонтекстЗаписи, Умолчание.Значение);
		ИначеЕсли Умолчание.Тип = "Число" или Умолчание.Тип = "Булево" Тогда
			ЗаписатьЗначение(КонтекстЗаписи, Число(Умолчание.Значение));
		ИначеЕсли Умолчание.Тип = "Дата" Тогда
			ЗначениеДаты = Вычислить("'" + Умолчание.Значение + "'");
			ЗаписатьЗначение(КонтекстЗаписи, ЗначениеДаты);
		КонецЕсли;		
		ЗаписатьКонецОбъекта(КонтекстЗаписи);
	КонецЦикла;
	ЗаписатьРазделительСтрок(КонтекстЗаписи);
	ЗаписатьКонецОбъекта(КонтекстЗаписи);

КонецПроцедуры // ЗаписатьУмолчанияПараметров()


#КонецОбласти

&НаКлиенте
Процедура Сохранить(Команда)
	Адрес = СохранитьНаСервере();
	ПолучитьФайл(Адрес, "image"); 
КонецПроцедуры


&НаКлиенте
Процедура ОперацииИмяОперацииОбработкаВыбора(Элемент, ВыбранноеЗначение, СтандартнаяОбработка)
	Элт = РасшифровкаОпераций.НайтиСтроки(Новый Структура("Мнемоника", ВыбранноеЗначение))[0];
	ТД = Элементы.Операции.ТекущиеДанные;
	ТД.КодОперации = Элт.Код;
	ТД.Описание = Элт.Название + Символы.ПС + Элт.ОписаниеАргумента;
КонецПроцедуры


&НаКлиенте
Процедура ОперацииПриОкончанииРедактирования(Элемент, НоваяСтрока, ОтменаРедактирования)
	Если Не ОтменаРедактирования Тогда
		ПеренумероватьАдресаКоманд();
	КонецЕсли;
КонецПроцедуры


&НаКлиенте
Процедура КонстантыПриОкончанииРедактирования(Элемент, НоваяСтрока, ОтменаРедактирования)
	Если Не ОтменаРедактирования Тогда
		ПеренумероватьСтрокиТаблицы(Константы, "Номер");
	КонецЕсли;
КонецПроцедуры

&НаКлиенте
Процедура КонстантыПослеУдаления(Элемент)
	ПеренумероватьСтрокиТаблицы(Константы, "Номер");
КонецПроцедуры

&НаКлиенте
Процедура КонстантыЗначениеНачалоВыбора(Элемент, ДанныеВыбора, СтандартнаяОбработка)
	СтандартнаяОбработка = Ложь;
	П = Новый Структура("Текст", Элементы.Константы.ТекущиеДанные.Значение);
	ОткрытьФорму("ВнешняяОбработка.Ассемблер.Форма.ВводТекста", П, Элемент);
КонецПроцедуры


&НаСервере
Процедура СобратьНаСервере()
	
	Если ПустаяСтрока(РабочийКаталог) Тогда
		РабочийКаталог = ПолучитьИмяВременногоФайла();
		СоздатьКаталог(РабочийКаталог);
		
		ДДОбработки = РеквизитФормыВЗначение("Объект").ПолучитьМакет("МакетОбработки");
		ДДОбработки.Записать(РабочийКаталог + ПолучитьРазделительПути() + "work.epf");
		
		Код = Неопределено;
		ЗапуститьПриложение("v8unpack -P work.epf decompiled", РабочийКаталог, Истина, Код);
		Если Код <> 0 Тогда
			Сообщить("Не удалось декомпилировать обработку. Возможно не установлен v8unpack в PATH");
			Возврат;
		КонецЕсли;
	КонецЕсли;
	
	ФайлОбраза = РабочийКаталог 
		+ ПолучитьРазделительПути() 
		+ "decompiled/4070aaa7-bb18-4293-9cd6-4112a9abe2ca.0/image"; // нормальный разделитель нормально работает
		
	ФП = ФайловыеПотоки.ОткрытьДляЗаписи(ФайлОбраза);
	СериализоватьМодуль(ФП);
	ФП.Закрыть();
	
	Код = Неопределено;
	ЗапуститьПриложение("v8unpack -B decompiled work.epf", РабочийКаталог, Истина, Код);
	Если Код <> 0 Тогда
		Сообщить("Не удалось декомпилировать обработку. Возможно не установлен v8unpack в PATH");
		Возврат;
	КонецЕсли;
	
КонецПроцедуры

&НаСервере
Процедура ЗапуститьНаСервере()
	
	ВнешниеОбработки.Создать(РабочийКаталог + ПолучитьРазделительПути() + "work.epf");

КонецПроцедуры // ЗапуститьНаСервере()


&НаКлиенте
Процедура Запустить(Команда)
	СобратьНаСервере();
	ЭтаФорма.Активизировать(); // окно декомпилятора прыгает
	ЗапуститьНаСервере();
КонецПроцедуры

&НаКлиенте
Процедура ПроцедурыПеременныеПриОкончанииРедактирования(Элемент, НоваяСтрока, ОтменаРедактирования)
	Если Не ОтменаРедактирования Тогда
		ПеренумероватьТекущиеПеременные();
	КонецЕсли;
КонецПроцедуры

&НаКлиенте
Процедура ПроцедурыПеременныеПослеУдаления(Элемент)
	ПеренумероватьТекущиеПеременные();
КонецПроцедуры

&НаКлиенте
Процедура ПеренумероватьТекущиеПеременные()
	ТекущиеДанные = Элементы.Процедуры.ТекущиеДанные;
	Если ТекущиеДанные = Неопределено Тогда
		Возврат;
	КонецЕсли;
	ПеренумероватьСтрокиТаблицы(ТекущиеДанные.Переменные, "Номер");
КонецПроцедуры

&НаКлиенте
Процедура ПроцедурыУмолчанияПриОкончанииРедактирования(Элемент, НоваяСтрока, ОтменаРедактирования)
	Если Не ОтменаРедактирования Тогда
		ПеренумероватьТекущиеУмолчания();
	КонецЕсли;
КонецПроцедуры

&НаКлиенте
Процедура ПроцедурыУмолчанияПослеУдаления(Элемент)
	ПеренумероватьТекущиеУмолчания();
КонецПроцедуры

&НаКлиенте
Процедура ПеренумероватьТекущиеУмолчания()
	ТекущиеДанные = Элементы.Процедуры.ТекущиеДанные;
	Если ТекущиеДанные = Неопределено Тогда
		Возврат;
	КонецЕсли;
	ПеренумероватьСтрокиТаблицы(ТекущиеДанные.Умолчания, "Номер");
КонецПроцедуры
